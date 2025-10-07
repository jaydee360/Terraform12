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
    "Environment" = "dev"
    "Owner"       = "Jason"
    "Source"      = "default_tags"
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

# vpc_config is a map of VPC definitions. Each VPC includes:
# - CIDR block and DNS settings
# - Optional Internet Gateway config
# - A map of named subnets, each with:
#   - CIDR block
#   - Availability Zone
#   - Flags for public exposure, route table, and NAT Gateway
variable "vpc_config" {
  type = map(object({
    vpc_cidr             = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, false)
    tags                 = optional(map(string))
    igw = optional(object({
      create = bool
      attach = bool
      tags   = map(string)
    }))
    subnets = map(object({
      subnet_cidr = string
      az          = string
      has_route_table = optional(bool, false)
      has_nat_gw  = optional(bool, false)
      tags        = optional(map(string))
    }))
  }))
}

# route_table_config is a map keyed by "vpc_key__subnet_key"
# Each entry defines:
#   - Whether to inject an IGW route
#   - Whether to inject a NAT route
#   - Optional custom routes (each with CIDR, target type, and target key)
#   - Optional tags for the route table
# Validation ensures:
#   - A route table cannot inject both IGW and NAT simultaneously
variable "route_table_config" {
  type = map(object({
    inject_igw    = optional(bool, false)
    inject_nat    = optional(bool, false)
    custom_routes = optional(list(object({
      cidr_block    = string
      target_type   = string
      target_key    = string
    })))
    tags          = optional(map(string),{})
  }))
  validation {
    condition = alltrue([for v in var.route_table_config : 
      !(v.inject_igw && v.inject_nat)
    ])
    error_message = "A route table cannot inject both IGW and NAT. Check: route_table_config."
  }
}

/* variable "ec2_config" {
  type = map(object({
    ami = string,
    instance_type = string,
    vpc = string
    subnet = string
    key_name = string
    associate_public_ip_address = optional(bool,false)
    assign_eip = optional(bool,false)
    vpc_security_group_ids = optional(set(string),null)
    user_data_script = optional(string,null)
    tags = optional(map(string),null)
  }))
} */

variable "ec2_config_v2" {
  type = map(object({
    ami = string,
    instance_type = string,
    key_name = string
    user_data_script = optional(string,null)
    eni_refs = list(string)
    tags = optional(map(string),null)
  }))
}

variable "eni_config" {
  type = map(object({
    vpc = string
    subnet = string
    description = optional(string, null)
    private_ip_list_enabled = optional(bool, false)
    private_ip_list = optional(set(string),null)
    private_ips_count = optional(number, null)
    security_groups = optional(set(string),null)
  }))
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
    })))
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
    }))
    egress = list(object({
      description = string
      from_port = optional(number)
      to_port = optional(number)
      protocol = string
      referenced_security_group_id = optional(string)
      prefix_list_id = optional(string)
      cidr_ipv4 = optional(string)
    }))
  }))
}





