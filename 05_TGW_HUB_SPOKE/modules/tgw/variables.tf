variable "default_tags" {
    type = map(string)
}

variable "tgw_key" {
    type = string
}

variable "tgw_object" {
  type = object({
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
  })
}
