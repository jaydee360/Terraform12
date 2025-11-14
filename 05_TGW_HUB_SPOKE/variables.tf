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

# --------------------------------------------------
# CloudWatch Log groups
# --------------------------------------------------

variable "aws_cloudwatch_log_group_config" {
  type = list(object({
    region = string
    service = string
    namespace = optional(string, "shared")
    type = string
    retention_in_days = number
  }))
} 

# --------------------------------------------------
# Firewall / Firewall Policy
# --------------------------------------------------

variable "fw_policy_config" {
  type = map(object({
    region = string
    stateless_default_actions = list(string)
    stateless_fragment_default_actions = list(string)
    stateful_default_actions = optional(list(string), null)
    rule_order = optional(string, null)
  }))
}

variable "fw_config" {
  type = map(object({
    region = string
    vpc_key = string
    subnet_keys = list(string)
    policy_key = string
    logging_config = optional(list(object({
      log_type = string
      log_destination_type = string
      log_group_ref = string
    })), [])
  }))
}

# --------------------------------------------------
# Transit Gateway
# --------------------------------------------------

variable "tgw_config" {
  type = map(object({
    account                             = optional(string)
    region                              = string
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

# --------------------------------------------------
# VPCs, Subnets and Related Infra
# --------------------------------------------------

variable "vpc_config" {
  type = map(object({
    region               = string
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

# --------------------------------------------------
# Routing Policies
# --------------------------------------------------

variable "routing_policies" {
  type = map(object({
    inject_igw    = optional(bool, false)
    inject_nat    = optional(bool, false)
    inject_tgw    = optional(bool, false)
    inject_fw     = optional(bool, false)
    tgw_key       = optional(string)
    tgw_app_mode  = optional(string, "disable")
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

# --------------------------------------------------
# EC2 Profiles and Instances
# --------------------------------------------------

variable "ec2_profiles" {
  type = map(object({
    ami_by_region         = optional(map(string), {})
    ami                   = optional(string)
    instance_type         = string
    key_name              = string
    user_data_script      = optional(string, null)
    iam_instance_profile  = optional(string, null)
    network_interfaces    = map(object({
      routing_policy        = string
      security_groups       = optional(set(string), null)
      assign_eip            = optional(bool, null)
    }))
    tags              = optional(map(string), null)
  }))
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_profiles : contains(keys(ec2_obj.network_interfaces), "nic0")
    ])
    error_message = "Each EC2 instance must define 'nic0' (primary network interface)"
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_profiles : alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.routing_policy == null ? true : contains(keys(var.routing_policies), eni_obj.routing_policy)])
    ])
    error_message = "EC2_PROFILE: Invalid Routing Policy: Network interfaces on ec2_profiles must reference a routing policy defined in var.routing_policies."
  }
  validation {
    condition = alltrue(flatten([
      for ec2_obj in var.ec2_profiles : [for eni_key in keys(ec2_obj.network_interfaces) :
        can(regex("^nic[0-9]$", eni_key))
      ]
    ]))
    error_message = "Network interface keys in ec2_profiles must follow the 'nicN' naming convention (e.g., 'nic0', 'nic1')."
  }
}

variable "ec2_instances" {
  type = map(object({
    region = string
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
      for ec2_obj in var.ec2_instances : contains(keys(var.ec2_profiles), ec2_obj.ec2_profile)
    ])
    error_message = "Invalid ec2_profile: One or more ec2_instances reference an invalid ec2_profile. Valid profiles are: ${join(", ", keys(var.ec2_profiles))}."
  }
  validation {
    condition = alltrue([
      for ec2_obj in var.ec2_instances : contains(keys(ec2_obj.network_interfaces), "nic0")
    ])
    error_message = "Each EC2 instance must define 'nic0' (primary network interface) for placement (VPC & AZ)"
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
      for ec2_obj in var.ec2_instances : alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.routing_policy == null ? true : contains(keys(var.routing_policies), eni_obj.routing_policy)])
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

# --------------------------------------------------
# Prefix Lists
# --------------------------------------------------

variable "prefix_list_config" {
  type = map(object({
    name = string
    address_family = string
    max_entries = number
    region = string
    entries = list(object({
      cidr = string
      description = optional(string)
    }))
    tags = optional(map(string), null)
  }))
}

# --------------------------------------------------
# Security Groups, SG Rules
# --------------------------------------------------

variable "security_groups" {
  type = map(object({
    description = optional(string)
    vpc_id = string
    region = string
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

# --------------------------------------------------
# IAM Role, Role Policy Attachment, Instance Profile 
# --------------------------------------------------

variable "iam_role_config" {
  type = map(object({
    name        = string
    description = string
    principal   = object({
      services    = optional(list(string), [])
      accounts    = optional(list(string), [])
    })
    managed_policies      = optional(list(string), [])
    iam_instance_profile  = optional(bool, false)
  }))
}