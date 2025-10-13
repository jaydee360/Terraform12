variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
  default     = "terraform"
}

variable "default_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "jason"
    DEFAULT_TAG = "yes"
  }
}

variable "az_lookup" {
  type = map(map(string))
  default = {
    "us-east-1" = {
      "a" = "us-east-1a"
      "b" = "us-east-1b"
      "c" = "us-east-1c"
      "d" = "us-east-1d"
    }
  }
}

variable "vpc_config" {
  type = map(object({
    vpc_cidr             = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, false)
    tags                 = optional(map(string), null)
    igw = optional(object({
      create = bool
      attach = bool
      tags   = map(string)
    }))
    subnets = map(object({
      subnet_cidr = string
      az          = string
      create_nat_gw  = optional(bool, false)
      routing_policy = optional(string, null)
      associate_routing_policy = optional(bool, false)
      override_routing_policy = optional(bool, false)
      tags        = optional(map(string), null)
    }))
  }))
}

variable "routing_policies" {
  type = map(object({
    inject_igw    = optional(bool, false)
    inject_nat    = optional(bool, false)
    custom_routes = optional(list(object({
      cidr_block    = string
      target_type   = string
      target_key    = string
    })))
    tags          = optional(map(string), null)
  }))
  validation {
    condition = alltrue([for rp in var.routing_policies : 
      !(rp.inject_igw && rp.inject_nat)
    ])
    error_message = "A route table cannot inject both IGW and NAT. Check: route_table_config."
  }
}

variable "route_table_config" {
  type = map(object({
    inject_igw    = optional(bool, false)
    inject_nat    = optional(bool, false)
    custom_routes = optional(list(object({
      cidr_block    = string
      target_type   = string
      target_key    = string
    })))
    tags          = optional(map(string), null)
  }))
  validation {
    condition = alltrue([for rtc in var.route_table_config : 
      !(rtc.inject_igw && rtc.inject_nat)
    ])
    error_message = "A route table cannot inject both IGW and NAT. Check: route_table_config."
  }
}

variable "ec2_config" {
  type = map(object({
    ami = string,
    instance_type = string,
    key_name = string
    user_data_script = optional(string, null)
    tags = optional(map(string), null)
    network_interfaces = map(object({
      vpc = string
      subnet = string
      description = optional(string, null)
      private_ip_list_enabled = optional(bool, false)
      private_ip_list = optional(set(string), null)
      private_ips_count = optional(number, null)
      security_groups = optional(set(string), null)
      assign_eip = optional(bool, false)
      tags = optional(map(string), null)
    }))
  }))
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_config : contains(keys(ec2_obj.network_interfaces), "nic0")
    ])
    error_message = "Each EC2 instance must define 'nic0' (primary network interface)"
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_config : length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc])) == 1])
    error_message = "Each EC2 instance must have all its network interfaces in the same VPC"
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_config : 
      alltrue([
        for eni_key, eni_obj in ec2_obj.network_interfaces : 
        contains(keys(local.subnet_map), "${eni_obj.vpc}__${eni_obj.subnet}")
      ]) 
      ? 
      (length(distinct([
        for eni_key, eni_obj in ec2_obj.network_interfaces : 
        local.subnet_map["${eni_obj.vpc}__${eni_obj.subnet}"].az
      ])) == 1)
      : true
    ])
    error_message = "Each EC2 instance must have all network interfaces in the same AZ"
  }
  validation {
    condition = alltrue(flatten([
      for ec2_obj in var.ec2_config : [for eni_key in keys(ec2_obj.network_interfaces) :
        can(regex("^nic[0-9]$", eni_key))
      ]
    ]))
    error_message = "Network interface keys must follow the naming convention 'nicN', where N is a single digit number (e.g., 'nic0', 'nic1', 'nic2')"
  }
  # Valid VPC / Subnet references are a dependency of EC2 Instance validation
  # EC2 instances with invalid VPC / Subnet references on NICs are not created. 
  # If an existing EC2 instance VPC / Subnet references become invald, the instance will be destroyed. This is the dafult behaviour. 
  # This behaviour can be changed by uncommenting the validation rule below 
  # Implementing the VPC / Subnet validation check at the variable level will stop the plan, therefor preventing creation or destruction of EC2 instance with invalid refs
  /*   
    validation {
      condition = alltrue([
        for ec2_obj in var.ec2_config : (
          alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(var.vpc_config), eni_obj.vpc)]) &&
          alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(local.subnet_map), "${eni_obj.vpc}__${eni_obj.subnet}")])
        )])
      error_message = "Each EC2 instance must have valid VPC and Subnet references on allnetwork interfaces"
    } 
  */
}

variable "prefix_list_config" {
  type = map(object({
    name = string
    address_family = string
    max_entries = number
    region = optional(string)
    entries = list(object({
      cidr = string
      description = optional(string)
    }))
    tags = optional(map(string), null)
  }))
}

variable "security_group_config" {
  type = map(object({
    description = string
    vpc_id = string
    ingress_ref = optional(string)
    ingress = optional(list(object({
      description = string
      from_port = number
      to_port = number
      protocol = string
      referenced_security_group_id = optional(string)
      prefix_list_id = optional(string)
      cidr_ipv4 = optional(string)
      tags = optional(map(string), null)
    })))
    egress_ref = optional(string)
    egress = optional(list(object({
      description = string
      from_port = optional(number)
      to_port = optional(number)
      protocol = string
      referenced_security_group_id = optional(string)
      prefix_list_id = optional(string)
      cidr_ipv4 = optional(string)
      tags = optional(map(string), null)
    })))
    tags = optional(map(string), null)
  }))
}

variable "shared_security_group_rules" {
  type = map(object({
    ingress = list(object({
      description = string
      from_port = number
      to_port = number
      protocol = string
      referenced_security_group_id = optional(string)
      prefix_list_id = optional(string)
      cidr_ipv4 = optional(string)
      tags = optional(map(string), null)
    }))
    egress = list(object({
      description = string
      from_port = optional(number)
      to_port = optional(number)
      protocol = string
      referenced_security_group_id = optional(string)
      prefix_list_id = optional(string)
      cidr_ipv4 = optional(string)
      tags = optional(map(string), null)
    }))
  }))
}





