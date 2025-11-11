locals {
  # Collect / assemble the attributes of the TGW_Attachment subnets.
  # Create a nested map, grouping these TGW_Attachment subnets by TGW > VPC > SUBNET LIST
  # Create a flat map for each 'aws_ec2_transit_gateway_vpc_attachment' 
  # Create two additional reverse lookup maps for reference:
  # - tgw_attachments_by_tgw_vpc (lookup TGW_Attchmnt by TGW > VPC)
  # - tgw_attached_cidrs_by_tgw_vpc (lookup VPC_CIDRs of TGW_attached VPCs)
  tgw_att_prefix = "TGWATT:"

  tgw_attachment_subnets = {
      for sn_key, sn_obj in local.subnet_map : 
      sn_key => {
          region  = sn_obj.region
          vpc_key = sn_obj.vpc_key
          routing_policy_name = sn_obj.routing_policy
          tgw_app_mode = try(var.routing_policies[sn_obj.routing_policy].tgw_app_mode, null)
          tgw_key = try(var.routing_policies[sn_obj.routing_policy].tgw_key, null)
      } if startswith(sn_obj.routing_policy, "tgw_attach_")  
      && try(var.routing_policies[sn_obj.routing_policy].tgw_key, null) != null 
      && contains(keys(local.tgw_map), var.routing_policies[sn_obj.routing_policy].tgw_key)
  }

  tgw_attachment_subnets_by_tgw_vpc = {
      for tgw_grp_key in distinct([for map_obj in local.tgw_attachment_subnets : map_obj.tgw_key]) : tgw_grp_key => {
          for vpc_grp_key in distinct([for map_obj2 in local.tgw_attachment_subnets : map_obj2.vpc_key if map_obj2.tgw_key == tgw_grp_key]) : vpc_grp_key => {
            subnets = [for sn_key, att_obj in local.tgw_attachment_subnets : sn_key if att_obj.tgw_key == tgw_grp_key && att_obj.vpc_key == vpc_grp_key]
            tgw_app_mode = one(distinct([for sn_key, att_obj in local.tgw_attachment_subnets : att_obj.tgw_app_mode if att_obj.tgw_key == tgw_grp_key && att_obj.vpc_key == vpc_grp_key]))
          }
      }
  }

  tgw_attachment_map = merge([
      for tgw_key, att_vpcs in local.tgw_attachment_subnets_by_tgw_vpc : {
          for vpc_key, obj in att_vpcs : "${local.tgw_att_prefix}${tgw_key}__${vpc_key}" => {
              tgw_key     = tgw_key
              tgw_app_mode = obj.tgw_app_mode
              vpc_key     = vpc_key
              vpc_region  = var.vpc_config[vpc_key].region
              subnet_keys = obj.subnets
          }
      }
  ]...)

  tgw_attachments_by_tgw_vpc = {
    for tgw_grp_key in distinct([for tgwatt_obj in local.tgw_attachment_map : tgwatt_obj.tgw_key]) : tgw_grp_key => {
      for vpc_grp_key in distinct([for tgwatt_obj in local.tgw_attachment_map : tgwatt_obj.vpc_key if tgwatt_obj.tgw_key == tgw_grp_key]) : vpc_grp_key => one([
        for tgwatt_key, tgwatt_obj in local.tgw_attachment_map : tgwatt_key if tgwatt_obj.tgw_key == tgw_grp_key && tgwatt_obj.vpc_key == vpc_grp_key
      ])
    }  
  }

  tgw_attachments_by_vpc = {
    for vpc_key in [for tgwatt_obj in local.tgw_attachment_map : tgwatt_obj.vpc_key] : vpc_key => one(flatten([
      for tgw_key, vpc_map in local.tgw_attachments_by_tgw_vpc : [
        for kk, oo in vpc_map : oo if kk == vpc_key
      ]
    ]))
  }

  tgw_attached_cidrs_by_tgw_vpc = {
    for tgwatt_key, tgwatt_obj in local.tgw_attachments_by_tgw_vpc : tgwatt_key => {
      for vpcatt_key, vpcatt_obj in tgwatt_obj : vpcatt_key => var.vpc_config[vpcatt_key].vpc_cidr
    }
  }
}

locals {
  # experiment with building full reachabiliity graph for tgw connected vpcs
  # attachment_src = local.tgw_attachments_by_vpc["vpc-edge"]
  # attachment_dst = local.tgw_attachments_by_vpc["vpc-db"]
  # src_associated_rt = local.tgw_route_table_associations_by_att_id[local.attachment_src]
  # dst_propagated_rt = local.tgw_route_table_propagations_by_att_id[local.attachment_dst]
  # src_dst_reachability = contains(local.dst_propagated_rt, local.src_associated_rt)

  tgw_route_table_associations_by_att_id = {
    for k, o in local.tgw_rt_association_map : o.associated_vpc_tgw_att_id => o.tgw_rt_key
  }
  tgw_route_table_propagations_by_att_id = {
    for att_grp_key in distinct([for att_obj in local.tgw_rt_propagation_map : att_obj.propagated_vpc_tgw_att_id]) : att_grp_key => [
      for att_obj in local.tgw_rt_propagation_map : att_obj.tgw_rt_key if att_obj.propagated_vpc_tgw_att_id == att_grp_key
    ]
  }

  reachability_map = {
    for src_vpc_key, src_attachment in local.tgw_attachments_by_vpc :
    src_vpc_key => {
      for dst_vpc_key, dst_attachment in local.tgw_attachments_by_vpc :
      dst_vpc_key => try(
        (contains(local.tgw_route_table_propagations_by_att_id[dst_attachment], local.tgw_route_table_associations_by_att_id[src_attachment])),
        null
      )
    }
  }
}

locals {
  # maps for various transit gateway related resources:
  # transit gateway / transit gateway route tables
  # transit gateway route table association / route table propagation

  tgw_map = {
      for tgw_key, tgw_obj in var.tgw_config : tgw_key => tgw_obj
  }

  tgw_rt_prefix = "TGWRT:"
  tgw_rt_map = merge([
      for tgw_key, tgw_obj in var.tgw_config : {
          for rt_key, rt_obj in tgw_obj.route_tables : 
          "${local.tgw_rt_prefix}${tgw_key}__${rt_key}" => merge(
              rt_obj, 
              {
                  tgw_key = tgw_key
                  rt_key = rt_key
                  region = tgw_obj.region
              }
          ) 
          if  tgw_obj.route_tables != null}
  ]...)

  tgw_rt_static_route_map = merge(flatten([for tgw_rt_key, tgw_rt_obj in local.tgw_rt_map : {
    for route in coalesce(tgw_rt_obj.routes, []) : "${tgw_rt_key}__${route.cidr_block}__${route.target_key}" => {
      rt_key = tgw_rt_key
      tgw_key = tgw_rt_obj.tgw_key
      region = tgw_rt_obj.region
      destination_prefix = route.cidr_block
      target_key = (route.target_key == "blackhole" ? "blackhole" : local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][route.target_key])
    } if route.target_key == "blackhole" || can(local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][route.target_key])
  }])...)

  tgw_rt_assoc_prefix = "__VPCASS:"
  tgw_rt_prop_prefix = "__VPCPROP:"

  # tgw_rt_association_map = merge([
  #   for tgw_rt_key, tgw_rt_obj in local.tgw_rt_map : {
  #     for vpc_assoc in coalesce(tgw_rt_obj.associations, []) : 
  #     "${tgw_rt_key}${local.tgw_rt_assoc_prefix}${vpc_assoc}" => {
  #       region                    = tgw_rt_obj.region
  #       tgw_key                   = tgw_rt_obj.tgw_key
  #       tgw_rt_key                = tgw_rt_key
  #       associated_vpc_name       = vpc_assoc
  #       associated_vpc_tgw_att_id = local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_assoc]
  #     } if can(local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_assoc])
  #   } 
  # ]...)

  tgw_rt_association_map = merge([
    for tgw_rt_key, tgw_rt_obj in local.tgw_rt_map : {
      for vpc_assoc in coalesce(tgw_rt_obj.associations, []) : 
      "${tgw_rt_key}${local.tgw_rt_assoc_prefix}${vpc_assoc}" => {
        region                    = tgw_rt_obj.region
        tgw_key                   = tgw_rt_obj.tgw_key
        tgw_rt_key                = tgw_rt_key
        tgw_rt_name               = tgw_rt_obj.rt_key
        associated_vpc_name       = vpc_assoc
        associated_vpc_tgw_att_id = try(local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_assoc], null)
      }
    } 
  ]...)

#   tgw_rt_propagation_map = merge([
#     for tgw_rt_key, tgw_rt_obj in local.tgw_rt_map : {
#       for vpc_prop in coalesce(tgw_rt_obj.propagations, []) : 
#       "${tgw_rt_key}${local.tgw_rt_prop_prefix}${vpc_prop}" => {
#         region                    = tgw_rt_obj.region
#         tgw_key                   = tgw_rt_obj.tgw_key
#         tgw_rt_key                = tgw_rt_key
#         propagated_vpc_name       = vpc_prop
#         propagated_vpc_tgw_att_id = local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_prop]
#       } if can(local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_prop])
#     } 
#   ]...)
# }

  tgw_rt_propagation_map = merge([
    for tgw_rt_key, tgw_rt_obj in local.tgw_rt_map : {
      for vpc_prop in coalesce(tgw_rt_obj.propagations, []) : 
      "${tgw_rt_key}${local.tgw_rt_prop_prefix}${vpc_prop}" => {
        region                    = tgw_rt_obj.region
        tgw_key                   = tgw_rt_obj.tgw_key
        tgw_rt_key                = tgw_rt_key
        tgw_rt_name               = tgw_rt_obj.rt_key
        propagated_vpc_name       = vpc_prop
        propagated_vpc_tgw_att_id = try(local.tgw_attachments_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_prop], null)
      }
    } 
  ]...)
  
}

locals {
  subnet_prefix = "SN:"
  subnet_map = merge(
    [for vpc_key, vpc_obj in var.vpc_config :
      {for subnet_key, subnet_obj in vpc_obj.subnets :
        "${local.subnet_prefix}${vpc_key}__${subnet_key}" => merge(
          subnet_obj, { 
            vpc_key = vpc_key, 
            subnet = subnet_key,
            region = vpc_obj.region
            az = var.az_lookup[vpc_obj.region][subnet_obj.az]
          }
        )
      }
  ]...)
}

locals {
  igw_prefix = "IGW:"
  igw_map = {
    for vpc_key, vpc_obj in var.vpc_config : 
    "${local.igw_prefix}${vpc_key}" => {
        vpc_key = vpc_key
        region = vpc_obj.region
    } if vpc_obj.create_igw
  }

  igw_lookup_map = {
    for igw_key, igw_obj in local.igw_map : igw_obj.vpc_key => igw_key
  }
}

locals {
  nat_gw_prefix = "NATGW:"
  nat_gw_map = {
    for sn_key, sn_obj in local.subnet_map :
    "${local.nat_gw_prefix}${sn_key}" => merge(
        sn_obj, 
        {subnet_key = sn_key}
      ) if sn_obj.create_natgw && lookup(local.subnet_has_igw_route, sn_key, false)
  }
}

locals {
  subnet_has_igw_route = {
    for rti_key, rti_obj in local.route_table_intent_map :
    rti_obj.subnet_key => "true"
    if rti_obj.routing_policy.inject_igw && can(local.igw_lookup_map[rti_obj.vpc_key])
  }
}

locals {
  rt_prefix = "RT:"
  route_table_map = {
    for sn_key, sn_obj in local.subnet_map : 
    "${local.rt_prefix}${sn_key}" => merge(
      sn_obj,
      {subnet_key = sn_key}
    ) if (sn_obj.routing_policy != null && contains(keys(var.routing_policies), sn_obj.routing_policy))
  } 
}

locals {
  routing_intent_prefix = "RI:"
  route_table_intent_map = {
    for rt_key, rt_obj in local.route_table_map :
    "${local.routing_intent_prefix}${rt_key}" => merge(
      rt_obj,
      {
        rt_key              = rt_key
        routing_policy_name = rt_obj.routing_policy
        routing_policy      = lookup(var.routing_policies, rt_obj.routing_policy, null)
      }
    ) 
  }
}

locals {
  igw_route_prefix = "IGW:"
  igw_route_map = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.igw_route_prefix}${rti_obj.rt_key}" => {
      region              = rti_obj.region
      rt_key              = rti_obj.rt_key
      target_key          = local.igw_lookup_map[rti_obj.vpc_key]
      destination_prefix  = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_igw && can(local.igw_lookup_map[rti_obj.vpc_key])
  }
}

locals {
  natgw_lookup_map_by_vpc_az = {
    for vpc_grp_key in distinct([
      for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key
    ]) : vpc_grp_key => {
      for az_grp_key in distinct([
        for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.az
        if nat_gw_obj.vpc_key == vpc_grp_key
      ]) : az_grp_key => [
        for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_key
        if nat_gw_obj.vpc_key == vpc_grp_key && nat_gw_obj.az == az_grp_key
      ]
    }
  }

  natgw_lookup_map_by_vpc = {
    for vpc_grp_key in distinct([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key]) :
    vpc_grp_key => [for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_key if nat_gw_obj.vpc_key == vpc_grp_key]
  }
}

locals {
  natgw_route_prefix = "NATGW:"
  natgw_route_map = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.natgw_route_prefix}${rti_obj.rt_key}" => {
      region              = rti_obj.region
      rt_key              = rti_obj.rt_key
      target_key          = try(local.natgw_lookup_map_by_vpc_az[rti_obj.vpc_key][rti_obj.az][0], local.natgw_lookup_map_by_vpc[rti_obj.vpc_key][0], null)
      destination_prefix  = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_nat && can(local.natgw_lookup_map_by_vpc[rti_obj.vpc_key][0])
  }
}

locals {
  fw_route_prefix = "FW:"
  fw_route_map = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.fw_route_prefix}${rti_obj.rt_key}" => {
      region              = rti_obj.region
      rt_key              = rti_obj.rt_key
      fw_key              = rti_obj.routing_policy.fw_key
      target_key          = try(local.fw_vpce_by_fw_vpc_az[rti_obj.routing_policy.fw_key][rti_obj.vpc_key][rti_obj.az], null)
      destination_prefix  = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_fw && can(var.fw_config[rti_obj.routing_policy.fw_key])
  }

  fw_vpce_by_fw_vpc_az = {
    for fw_key, fw_obj in aws_networkfirewall_firewall.main : fw_key => {
      var.fw_config[fw_key].vpc_key = {
        for sync_state in fw_obj.firewall_status[0].sync_states : sync_state.availability_zone => sync_state.attachment[0].endpoint_id
      }
    }
  }

}

locals {
  tgw_route_prefix = "TGW:"

  tgw_dynamic_route_map = merge(flatten([
    for rti_key, rti_obj in local.route_table_intent_map : [
      for tgw in [for tgw_key, vpc_keys in local.tgw_attachments_by_tgw_vpc : tgw_key if contains(keys(vpc_keys), rti_obj.vpc_key)] : {
        for vpc in [for vpc_key, vpc_cidr in local.tgw_attached_cidrs_by_tgw_vpc[tgw] : vpc_key if vpc_key != rti_obj.vpc_key] : "${local.tgw_route_prefix}${rti_obj.rt_key}__${vpc}" => {
          region = rti_obj.region
          rt_key = rti_obj.rt_key
          destination_prefix = local.tgw_attached_cidrs_by_tgw_vpc[tgw][vpc]
          target_key = tgw
        }
      }
    ] if rti_obj.routing_policy.inject_tgw
  ])...)

  tgw_static_route_map = merge(flatten([
    for rti_key, rti_obj in local.route_table_intent_map : {
      for route in coalesce(rti_obj.routing_policy.routes, []) : "${local.tgw_route_prefix}${rti_obj.rt_key}__${route.cidr_block}" => {
        region             = rti_obj.region
        rt_key             = rti_obj.rt_key
        destination_prefix = route.cidr_block
        target_key         = route.target_key
      } if route.target_type == "tgw" && contains(keys(local.tgw_map), route.target_key)
    }
  ])...)


  tgw_route_map = merge(
    local.tgw_dynamic_route_map, 
    local.tgw_static_route_map
  )
}

locals {
  rt_assoc_prefix = "RTASS:"
  subnet_route_table_associations = {
    for rt_key, rt_obj in local.route_table_map : 
    "${local.rt_assoc_prefix}${rt_key}" => {
      region          = rt_obj.region
      subnet_id       = rt_obj.subnet_key
      route_table_id  = rt_key
    }
  }
}

locals {
  debug_tgw_routes = {
    for vpc_grp in distinct([for kk, oo in local.tgw_route_map : split("__", oo.rt_key)[0]]) : vpc_grp => [
      for ooo in local.tgw_route_map : "${split("__", ooo.rt_key)[1]} > ${ooo.destination_prefix} > ${ooo.target_key}" 
      if split("__", ooo.rt_key)[0] == vpc_grp
    ]
  }
  debug_igw_routes = {
    for vpc_grp in distinct([for kk, oo in local.igw_route_map : split("__", oo.rt_key)[0]]) : vpc_grp => [
      for ooo in local.igw_route_map : "${split("__", ooo.rt_key)[1]} > ${ooo.destination_prefix} > ${ooo.target_key}" 
      if split("__", ooo.rt_key)[0] == vpc_grp
    ]
  }
  debug_natgw_routes = {
    for vpc_grp in distinct([for kk, oo in local.natgw_route_map : split("__", oo.rt_key)[0]]) : vpc_grp => [
      for ooo in local.natgw_route_map : "${split("__", ooo.rt_key)[1]} > ${ooo.destination_prefix} > ${ooo.target_key}" 
      if split("__", ooo.rt_key)[0] == vpc_grp
    ]
  }

  debug_fw_routes = {
    for vpc_grp in distinct([for kk, oo in local.fw_route_map : split("__", oo.rt_key)[0]]) : vpc_grp => [
      for ooo in local.fw_route_map : "${split("__", ooo.rt_key)[1]} > ${ooo.destination_prefix} > ${ooo.target_key}" 
      if split("__", ooo.rt_key)[0] == vpc_grp
    ]
  }

  debug_tgw_rt_static_routes = [
    for k, o in local.tgw_rt_static_route_map : "${o.tgw_key} > ${split("__", k)[1]} > ${o.destination_prefix} > ${split("__", k)[3]}"
  ]

  debug_all_subnet_routes = flatten([
    for route_type, route_map in {
      tgw   = local.tgw_route_map
      igw   = local.igw_route_map
      natgw = local.natgw_route_map
    } : [
      for ooo in route_map :
      "${upper(route_type)} > ${split(":",split("__", ooo.rt_key)[0])[2]} > ${split("__", ooo.rt_key)[1]} > ${ooo.destination_prefix} > ${ooo.target_key}"
    ]
  ])

  debug_tgw_rt_associations = {
    for rt_name in distinct([for k, o in local.tgw_rt_association_map : o.tgw_rt_name]) : rt_name => [
      for kk, oo in local.tgw_rt_association_map : oo.associated_vpc_name 
      if oo.tgw_rt_name == rt_name
    ]
  }

  debug_tgw_rt_associations_simple = {for k, o in local.debug_tgw_rt_associations : join(" | ", sort(o)) => k}
  
  debug_tgw_rt_propagations = {
    for rt_name in distinct([for k, o in local.tgw_rt_propagation_map : o.tgw_rt_name]) : rt_name => [
      for kk, oo in local.tgw_rt_propagation_map : oo.propagated_vpc_name 
      if oo.tgw_rt_name == rt_name
    ]
  }

  debug_tgw_rt_propagations_simple = {for k, o in local.debug_tgw_rt_propagations : join(" | ", sort(o)) => k}

}
