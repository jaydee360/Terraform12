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
    Source = "default_tags"
  }
}

variable "az_lookup" {
  type = map(map(string))
  default = {
    us-east-1 = {
      "a" = "us-east-1a"
      "b" = "us-east-1b"
      "c" = "us-east-1c"
      "d" = "us-east-1d"
    }
    us-east-2 = {
      "a" = "us-east-2a"
      "b" = "us-east-2b"
      "c" = "us-east-2c"
    }
  }
}

variable "tgw_config" {
  type = map(object({
    account                             = optional(string)
    region                              = optional(string)
    amazon_side_asn                     = optional(number)
    description                         = optional(string)
    route_tables                        = optional(map(object({
      is_default                        = optional(bool, false)
      associations                      = optional(list(string))
      propagations                      = optional(list(string))
      routes                            = optional(list(object({
        cidr_block                      = string
        target_type                     = string
        target_key                      = string
      })))
    })))
    dns_support                         = optional(string, "enable")
    auto_accept_shared_attachments      = optional(string, "disable")
    default_route_table_association     = optional(string, "enable")
    default_route_table_propagation     = optional(string, "enable")
    security_group_referencing_support  = optional(string, "disable")
    transit_gateway_cidr_blocks         = optional(string)
    tags                                = optional(map(string))
  }))
}

variable "vpc_config" {
  type = map(object({
    region               = optional(string)
    vpc_cidr             = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, false)
    tags                 = optional(map(string), {})
    create_igw           = optional(bool, false)
    subnets = map(object({
      subnet_cidr     = string
      az              = string
      create_natgw    = optional(bool, false)
      routing_policy  = optional(string, null)
      tags            = optional(map(string), {})
    }))
  }))
}

variable "routing_policies" {
  type = map(object({
    inject_igw    = optional(bool, false)
    inject_nat    = optional(bool, false)
    inject_peerings = optional(bool, false)
    tgw_key   = optional(string)
    tags          = optional(map(string), null)
  }))
}
