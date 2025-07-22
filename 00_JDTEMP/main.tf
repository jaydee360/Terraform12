locals {
  rg_by_provider = {
    for ko, vo in distinct([for ki, vi in var.resource_groups : vi.provider_alias]) : vo => {
      for kii, vii in var.resource_groups : kii => vii if vo == vii.provider_alias
    }
  }
}
locals {
  new_rg_by_provider = {
    for vo in distinct([for vi in var.resource_groups : vi.provider_alias]) : vo => {
      for kii, vii in var.resource_groups : kii => vii if vo == vii.provider_alias
    }
  }
}

locals {
  new_rg_by_provider_v2 = {
    for alias in distinct([for data in var.resource_groups : data.provider_alias]) : alias => {
      for rg_name, rg_data in var.resource_groups : rg_name => rg_data if alias == rg_data.provider_alias
    }
  }
}


locals {
  rg_tags = {
    for rg_key, rg_val in var.resource_groups :
    rg_key => rg_val.tags
  }
}

locals {
  test = flatten([
      for network in var.networks : [for subnet_key, subnet in network.subnets : {
          "${subnet_key}-subnet" = subnet.cidr_block
      }]
  ])
}

# locals {
#     rg_by_provider = {
#         for provider_alias_key, provider_alias_value in distinct([
#             for group_name, group_config in var.resource_groups : group_config.provider_alias
#         ]) : provider_alias_value => {
#             for resource_group_name, resource_group_config in var.resource_groups :
#             resource_group_name => resource_group_config
#             if resource_group_config.provider_alias == provider_alias_value
#         }
#     }
# }


