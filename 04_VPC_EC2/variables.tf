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
    create_igw           = optional(bool, false)
    subnets = map(object({
      subnet_cidr     = string
      az              = string
      create_natgw    = optional(bool, false)
      routing_policy  = optional(string, null)
      tags            = optional(map(string), null)
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

variable "ec2_profiles" {
  type = map(object({
    ami = string,
    instance_type = string,
    key_name = string
    user_data_script = optional(string, null)
    network_interfaces = map(object({
      routing_policy = string
      security_groups = optional(set(string), null)
      assign_eip = optional(bool, null)
    }))
    tags = optional(map(string), null)
  }))
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_profiles : contains(keys(ec2_obj.network_interfaces), "nic0")
    ])
    error_message = "Each EC2 instance must define 'nic0' (primary network interface)"
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_profiles : alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.routing_policy == null ? true : can(contains(keys(var.routing_policies), eni_obj.routing_policy))])
    ])
    error_message = "Invalid Routing Policy: Network interfaces on ec2_profiles must reference a routing policy defined in var.routing_policies."
  }
  validation {
    condition = alltrue(flatten([
      for ec2_obj in var.ec2_profiles : [for eni_key in keys(ec2_obj.network_interfaces) :
        can(regex("^nic[0-9]$", eni_key))
      ]
    ]))
    error_message = "Network interface keys in ec2_profiles must follow the 'nicN' naming convention (e.g., 'nic0', 'nic1')."
  }
  # validation {
  #   condition = alltrue([
  #     for ec2_obj in var.ec2_profiles : alltrue([
  #       for eni_key, eni_obj in ec2_obj.network_interfaces :
  #       eni_obj.security_groups == null ? true :
  #       alltrue([for sg in eni_obj.security_groups : contains(keys(var.security_group_config), sg)])
  #     ])
  #   ])
  #   error_message = "One or more EC2 network interfaces reference unknown security groups. Check var.security_group_config."
  # }

}

variable "ec2_instances" {
  type = map(object({
    ec2_profile = string
        network_interfaces = map(object({
          routing_policy = optional(string, null)
          security_groups = optional(set(string), null)
          assign_eip = optional(bool, null)
          vpc = string
          az  = string
        }))
  }))
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_instances : contains(keys(ec2_obj.network_interfaces), "nic0")
    ])
    error_message = "Each EC2 instance must define 'nic0' (primary network interface)"
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_instances : length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc])) == 1])
    error_message = "Each EC2 instance must have all its network interfaces in the same VPC"
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_instances : length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.az])) == 1])
    error_message = "Each EC2 instance must have all network interfaces in the same AZ"
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_instances : alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.routing_policy == null ? true : can(contains(keys(var.routing_policies), eni_obj.routing_policy))])
    ])
    error_message = "Invalid Routing Policy: Network interfaces on ec2_instances must specify a valid routing policy (var.routing_policy)"
  }
  validation {
    condition = alltrue(flatten([
      for ec2_obj in var.ec2_instances : [for eni_key in keys(ec2_obj.network_interfaces) :
        can(regex("^nic[0-9]$", eni_key))
      ]
    ]))
    error_message = "Network interface keys in ec2_instances must follow the 'nicN' naming convention (e.g., 'nic0', 'nic1')."
  }
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

variable "security_groups" {
  type = map(object({
    description = optional(string)
    vpc_id = string
    ingress_ref = list(string)
    egress_ref = list(string)
    tags = optional(map(string), null)
  }))
  validation {
    condition = alltrue([
      for sg_key, sg_obj in var.security_groups : length(sg_obj.ingress_ref) == 0 ? true :
      alltrue([
        for rule_set in sg_obj.ingress_ref : contains(keys(var.security_group_rule_sets), rule_set)
      ])
    ])
    error_message = "One or more security groups reference undefined INGRESS rule sets. All values in ingress_ref must match keys in var.security_group_rule_sets."
  }
  validation {
    condition = alltrue([
      for sg_key, sg_obj in var.security_groups : length(sg_obj.egress_ref) == 0 ? true :
      alltrue([
        for rule_set in sg_obj.egress_ref : contains(keys(var.security_group_rule_sets), rule_set)
      ])
    ])
    error_message = "One or more security groups reference undefined EGRESS rule sets. All values in egress_ref must match keys in var.security_group_rule_sets."
  }
}

variable "security_group_rule_sets" {
  type = map(list(object({
    description = optional(string)
    from_port = optional(number)
    to_port = optional(number)
    ip_protocol = string
    referenced_security_group_id = optional(string)
    prefix_list_id = optional(string)
    cidr_ipv4 = optional(string)
    tags = optional(map(string), null)
  })))
  # validation is done using lifecycle precondition in the resource block
}

