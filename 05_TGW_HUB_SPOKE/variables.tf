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
    "us-east-1" = {
      "a" = "us-east-1a"
      "b" = "us-east-1b"
      "c" = "us-east-1c"
      "d" = "us-east-1d"
    }
  }
}

variable "tgw_config" {
  type = map(object({
    account                             = optional(string)
    region                              = optional(string)
    amazon_side_asn                     = optional(number)
    description                         = optional(string)
    dns_support                         = optional(string, "enable")
    auto_accept_shared_attachments      = optional(string, "disable")
    default_route_table_association     = optional(string, "enable")
    default_route_table_propagation     = optional(string, "enable")
    security_group_referencing_support  = optional(string, "disable")
    transit_gateway_cidr_blocks         = optional(string)
    tags                                = optional(map(string))
  }))
}
