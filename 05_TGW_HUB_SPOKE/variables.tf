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

variable "fw_policy_config" {
  type = map(object({
    region = string
    stateless_default_actions = list(string)
    stateless_fragment_default_actions = list(string)
  }))
}

variable "fw_config" {
  type = map(object({
    region = string
    vpc_id = string
    subnet_ids = list(string)
    policy_key = string
  }))
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
        target_key                      = string
      })))
      tags                              = optional(map(string))
    })))
    dns_support                         = optional(string, "enable")
    auto_accept_shared_attachments      = optional(string, "disable")
    default_route_table_association     = optional(string, "enable")
    default_route_table_propagation     = optional(string, "enable")
    security_group_referencing_support  = optional(string, "disable")
    transit_gateway_cidr_blocks         = optional(string)
    tags                                = optional(map(string))
  }))
  # validation {
  #   condition = alltrue(flatten([
  #     for tgw_key, tgw_obj in var.tgw_config : [
  #       for tgw_rt_obj in tgw_obj.route_tables : [
  #         for vpc_ref in tgw_rt_obj.associations : 
  #         can(local.tgw_att_by_tgw_vpc[tgw_key][vpc_ref])
  #       ]
  #     ]
  #   ]))
  #   error_message = "Invalid TGW Route Table Association: Associations must reference VPCs attached to the TGW"
  # }
  # validation {
  #   condition = alltrue(flatten([
  #     for tgw_key, tgw_obj in var.tgw_config : [
  #       for tgw_rt_obj in tgw_obj.route_tables : [
  #         for vpc_ref in tgw_rt_obj.propagations : 
  #         can(local.tgw_att_by_tgw_vpc[tgw_key][vpc_ref])
  #       ]
  #     ]
  #   ]))
  #   error_message = "Invalid TGW Route Table Progagation: Propagations must reference VPCs attached to the TGW"
  # }
}

variable "vpc_config" {
  type = map(object({
    region               = optional(string)
    vpc_cidr             = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
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
    inject_tgw    = optional(bool, false)
    inject_fw     = optional(bool, false)
    tgw_key       = optional(string)
    fw_key        = optional(string)
    routes        = optional(list(object({
      cidr_block  = string
      target_type = string
      target_key  = string
    })))
    tags          = optional(map(string), null)
  }))
  validation {
    condition = alltrue([
      for tgw_target_key in [for rp_key, rp_obj in var.routing_policies : rp_obj.tgw_key if startswith(rp_key, "tgw_attach")] : 
      can(var.tgw_config[tgw_target_key])
    ])
    error_message = "Invalid tgw_key in 'tgw_attach' policy. All 'tgw_attach' policies must reference a valid tgw_key"
  }
}
