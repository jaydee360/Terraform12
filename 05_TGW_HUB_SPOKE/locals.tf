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
# ---------------------

# 🔹 merged_ec2_instance_map, 🔹 resolved_ec2_instance_map, 🔹 valid_ec2_instance_map
# ------------------------------------------------------------------------------------
# Purpose: Merges EC2 instances from profiles, resolves target subnets, filters valid EC2 instances.

# Used in:
# Locals: 🔹 valid_eni_map, 🔹 ec2_eni_lookup_map
# Resources: 🔹 aws_instance.main, 🔹 aws_network_interface_attachment.main
# Depends on: 🔹 var.ec2_instances, 🔹 var.ec2_profiles, 🔹 subnet_lookup_by_routing_policy_vpc_az, 🔹 subnet_map
locals {
  merged_ec2_instance_map = {
    for inst_key, inst_obj in var.ec2_instances : inst_key => merge(
      var.ec2_profiles[inst_obj.ec2_profile],
      inst_obj,
      {
        ami       = var.ec2_profiles[inst_obj.ec2_profile].ami_by_region[inst_obj.region]
        # key_name  = replace(var.ec2_profiles[inst_obj.ec2_profile].key_name, "region", inst_obj.region)
        network_interfaces = {for nic_key in distinct(concat(
          keys(try(var.ec2_profiles[inst_obj.ec2_profile].network_interfaces, {})),
          keys(inst_obj.network_interfaces))) : nic_key => merge(
            try(var.ec2_profiles[inst_obj.ec2_profile].network_interfaces[nic_key], {}),
            {
              for key, value in try(inst_obj.network_interfaces[nic_key], {}) : key => (
                value != null
                ? value
                : try(var.ec2_profiles[inst_obj.ec2_profile].network_interfaces[nic_key][key], null)
              )
            },
            {
              az = try(var.az_lookup[inst_obj.region][try(inst_obj.network_interfaces[nic_key].az, null)], null)
            }
          )
        }
      }
    ) if contains(keys(var.ec2_profiles), inst_obj.ec2_profile)
  }

  resolved_ec2_instance_map = {
    for inst_key, inst_obj in local.merged_ec2_instance_map : 
    inst_key => merge(
      inst_obj,
      {network_interfaces = {
        for nic_key, nic_obj in inst_obj.network_interfaces : nic_key => merge(
          nic_obj,
          {
            subnet_id = try(local.subnet_lookup_by_routing_policy_vpc_az[nic_obj.routing_policy][nic_obj.vpc][nic_obj.az], null)
          }
        )
      }}
    )
  }

  valid_ec2_instance_map = {
    for ec2_key, ec2_obj in local.resolved_ec2_instance_map : ec2_key => ec2_obj if (
      alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : can(contains(keys(var.vpc_config), eni_obj.vpc))]) &&
      alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : can(contains(keys(local.subnet_map), eni_obj.subnet_id))])
    )
  }
}

# 🔹 subnet_lookup_by_routing_policy_vpc_az
# -----------------------------------------
# Purpose: Enables subnet resolution (Routing Policy > VPC > AZ > Subnet) for EC2 placement.

# Used in:
# Locals: 🔹 resolved_ec2_instance_map
# Resources: indirectly via 🔹 aws_instance.main
# Depends on: 🔹 minimal_rti_list (minimised from 🔹 route_table_intent_map)
locals {
  minimal_rti_list = [
    for rti_key, rti_obj in local.route_table_intent_map : {
      routing_policy_name = rti_obj.routing_policy_name
      vpc_key = rti_obj.vpc_key
      az = rti_obj.az
      subnet_key = rti_obj.subnet_key
    }
  ]

  subnet_lookup_by_routing_policy_vpc_az = {
    for rp_grp in distinct([for rti_element in local.minimal_rti_list : rti_element.routing_policy_name]) :
    rp_grp => {for vpc_grp in distinct([for rti_element in local.minimal_rti_list : rti_element.vpc_key if rti_element.routing_policy_name == rp_grp]) : 
      vpc_grp => {for az_grp in distinct([for rti_element in local.minimal_rti_list : rti_element.az if rti_element.routing_policy_name == rp_grp && rti_element.vpc_key == vpc_grp]) : 
        az_grp => try(one([for rti_element in local.minimal_rti_list : rti_element.subnet_key if rti_element.routing_policy_name == rp_grp && rti_element.vpc_key == vpc_grp && rti_element.az == az_grp]), null)
      } 
    }
  }
}


# 🔹 valid_eni_map
# ----------------
# Purpose: Builds enriched ENI objects from valid EC2 instances.

# Used in:
# Locals: 🔹 valid_eni_eip_map, 🔹 valid_eni_attachments, 🔹 ec2_eni_lookup_map, 🔹 diagnostics
# Resources: 🔹 aws_network_interface.main
# Depends on: 🔹 valid_ec2_instance_map, 🔹 valid_security_group_map
locals {
  # valid_eni_map_old = merge([ 
  #   for ec2_key, ec2_obj in local.valid_ec2_instance_map : {for eni_key, eni_obj in ec2_obj.network_interfaces : "${ec2_key}__${eni_key}" => merge(
  #     eni_obj, {
  #       # subnet_id       = "${eni_obj.vpc}__${eni_obj.subnet}"
  #       region          = ec2_obj.region
  #       ec2_key         = ec2_key
  #       ec2_nic_key     = eni_key
  #       index           = tonumber(substr(eni_key, length(eni_key) - 1, 1))
  #       security_groups = [
  #                           for sg  in coalesce(eni_obj.security_groups, []) : sg  
  #                           if contains(keys(local.valid_security_group_map), sg) && 
  #                           local.valid_security_group_map[sg].vpc_id == eni_obj.vpc
  #                         ]
  #       tags            = ec2_obj.tags
  #     }
  #   )}
  # ]...)

  valid_eni_map = merge([ 
    for ec2_key, ec2_obj in local.valid_ec2_instance_map : {for eni_key, eni_obj in ec2_obj.network_interfaces : "${ec2_key}__${eni_key}" => merge(
      eni_obj, {
        # subnet_id       = "${eni_obj.vpc}__${eni_obj.subnet}"
        region          = ec2_obj.region
        ec2_key         = ec2_key
        ec2_nic_key     = eni_key
        index           = tonumber(substr(eni_key, length(eni_key) - 1, 1))
        security_groups = [
                            for sg  in coalesce(eni_obj.security_groups, []) : "${eni_obj.vpc}__${sg}"  
                            if contains(keys(local.valid_security_group_map), "${eni_obj.vpc}__${sg}") 
                          ]
        tags            = ec2_obj.tags
      }
    )}
  ]...)


} 

# 🔹 valid_eni_eip_map
# --------------------
# Purpose: Filters ENIs eligible for Elastic IPs.

# Used in:
# Resources: 🔹 aws_eip.eni
# Depends on: 🔹 valid_eni_map, 🔹 subnet_has_igw_route
locals {
  valid_eni_eip_map = {
    for eip_map_key, eip_map_obj in local.valid_eni_map : eip_map_key => {
      region                = eip_map_obj.region
      assign_eip            = eip_map_obj.assign_eip
      subnet_id             = eip_map_obj.subnet_id
      subnet_has_igw_route  = lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
      tags                  = eip_map_obj.tags
    } if eip_map_obj.assign_eip && lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
  }
} 

# 🔹 ec2_eni_lookup_map
# ---------------------
# Purpose: Reverse lookup of ENI keys by EC2 instance primary NIC.

# Used in:
# Resources: 🔹 aws_instance.main
# Depends on: 🔹 valid_eni_map, 🔹 valid_ec2_instance_map
locals {
  primary_nic_name = "nic0"

  ec2_eni_lookup_map = {
    for ec2_key, ec2_obj in local.valid_ec2_instance_map : ec2_key => {
      for eni_map_key, eni_map_obj in local.valid_eni_map : eni_map_obj.ec2_nic_key => eni_map_key
      if eni_map_obj.ec2_key == ec2_key
    }
  }
}

# 🔹 valid_eni_attachments
# ------------------------
# Purpose: Maps secondary ENIs to EC2 instances for attachment.

# Used in:
# Resources: 🔹 aws_network_interface_attachment.main
# Depends on: 🔹 valid_eni_map
locals {
  valid_eni_attachments = {
    for eni_map_key, eni_map_obj in local.valid_eni_map : eni_map_key => {
        region                = eni_map_obj.region
        instance_id           = eni_map_obj.ec2_key
        network_interface_id  = eni_map_key
        device_index          = eni_map_obj.index
      }
    if eni_map_obj.index > 0
  } 
} 


# 🔹 prefix_list_map
# -------------------
# Purpose: Direct mapping of prefix list config.

# Used in:
# Resources: 🔹 aws_ec2_managed_prefix_list.main, 🔹 SG rule resolution
# Depends on: 🔹 var.prefix_list_config
locals {
  prefix_list_map = {
    for pl_key, pl_obj in var.prefix_list_config : pl_key => pl_obj 
  }
}


# 🔹 valid_security_group_map
# ---------------------------
# Purpose: Filters SGs with valid VPC references.

# Used in:
# Locals: 🔹 normalised_ingress_ref_rules, 🔹 normalised_egress_ref_rules
# Resources: 🔹 aws_security_group.main
# Depends on: 🔹 var.security_groups, 🔹 var.vpc_config
locals {
  valid_security_group_map = merge([
    for sg_key, sg_obj in var.security_groups : {
      for vpc_key, vpc_obj in var.vpc_config : 
      "${vpc_key}__${sg_key}" => merge(sg_obj, {vpc_id = vpc_key})
    }
  ]...)
}

# 🔹 normalised_ingress_ref_rules, hashed_ingress_rules, ingress_rules_map
# ------------------------------------------------------------------------
# Purpose: Normalize, hash, deduplicate and map ingress rules.

# Used in:
# Locals: 🔹 hashed_ingress_rules, 🔹 ingress_rules_map
# Resources: 🔹 aws_vpc_security_group_ingress_rule.main
# Depends on: 🔹 valid_security_group_map, var.security_group_rule_sets, 🔹 local.hash_exclusions
locals {
  hash_exclusions = ["description", "rule_set_ref", "tags", "region"]

  normalised_ingress_ref_rules = flatten([
    for sg_key, sg_obj in local.valid_security_group_map : [for rule_set in sg_obj.ingress_ref : [for rule in var.security_group_rule_sets[rule_set] : merge(
      rule,
      ( # if referenced_security_group_id != null, check it exists in the map of valid SGs, and is in the same VPC as the SG
        rule.referenced_security_group_id != null && 
        (contains(keys(local.valid_security_group_map), "${sg_obj.vpc_id}__${rule.referenced_security_group_id}"))
      ) ? {
        referenced_security_group_id  = "${sg_obj.vpc_id}__${rule.referenced_security_group_id}"
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : (rule.prefix_list_id != null && contains(keys(local.prefix_list_map), rule.prefix_list_id)) ? {
        referenced_security_group_id  = null
        prefix_list_id                = rule.prefix_list_id 
        cidr_ipv4                     = null
      } : {
        referenced_security_group_id  = null
        prefix_list_id                = null
        cidr_ipv4                     = rule.cidr_ipv4
      },
      {
        sg_key  = sg_key,
        rule_set_ref = rule_set
        region = sg_obj.region
      }
    )] if length(sg_obj.ingress_ref) > 0 && contains(keys(var.security_group_rule_sets), rule_set)]
  ])

  # HASHING (INGRESS)
  # -----------------
  hashed_ingress_rules = flatten([
    for rule_obj in local.normalised_ingress_ref_rules : 
    merge(
      rule_obj, 
      {
        rule_hash = md5(jsonencode(
          {for key, value in rule_obj : key => value if !contains(local.hash_exclusions, key)}
        ))
      }
    )
  ])

  # AGGREGATION (INGRESS)
  # ---------------------
  # Build a map of unique ingress rules keyed by rule_hash
  # - Ensures deduplication and traceability
  # This map is used to create the actual 'aws_vpc_security_group_ingress_rule' resource
  ingress_rules_map = {
    for rule in distinct(local.hashed_ingress_rules) :
    rule.rule_hash => rule
  }
}

# 🔹 normalised_egress_ref_rules, hashed_egress_rules, egress_rules_map
# ---------------------------------------------------------------------
# Purpose: Normalize, hash, deduplicate and map egress rules.

# Used in:
# Locals: 🔹 hashed_egress_rules, 🔹 egress_rules_map
# Resources: 🔹 aws_vpc_security_group_egress_rule.main
# Depends on: 🔹 valid_security_group_map, var.security_group_rule_sets, 🔹 local.hash_exclusions

locals {
  # NORMALISATION & ENRICHMENT (REFERENCED RULES - EGRESS)
  # ------------------------------------------------------
  normalised_egress_ref_rules = flatten([
    for sg_key, sg_obj in local.valid_security_group_map : [for rule_set in sg_obj.egress_ref : [for rule in var.security_group_rule_sets[rule_set] : merge(
      rule,
      ( # if referenced_security_group_id != null, check it exists in the map of valid SGs, and is in the same VPC as the SG
        rule.referenced_security_group_id != null && 
        (contains(keys(local.valid_security_group_map), "${sg_obj.vpc_id}__${rule.referenced_security_group_id}"))
      ) 
      ? {
        referenced_security_group_id  = "${sg_obj.vpc_id}__${rule.referenced_security_group_id}"
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : (rule.prefix_list_id != null && contains(keys(local.prefix_list_map), rule.prefix_list_id)) ? {
        referenced_security_group_id  = null
        prefix_list_id                = rule.prefix_list_id
        cidr_ipv4                     = null
      } : {
        referenced_security_group_id  = null
        prefix_list_id                = null
        cidr_ipv4                     = rule.cidr_ipv4
      },
      {
        sg_key  = sg_key,
        rule_set_ref = rule_set
        region = sg_obj.region
      }
    )] if length(sg_obj.egress_ref) > 0 && contains(keys(var.security_group_rule_sets), rule_set)]
  ])

  # HASHING (EGRESS)
  # ----------------
  hashed_egress_rules = flatten([
    for rule_obj in local.normalised_egress_ref_rules : 
    merge(
      rule_obj, 
      {
        rule_hash = md5(jsonencode(
          {for key, value in rule_obj : key => value if !contains(local.hash_exclusions, key)}
        ))
      }
    )
  ])

  # AGGREGATION (EGRESS)
  # --------------------
  egress_rules_map = {
    for rule in distinct(local.hashed_egress_rules) :
    rule.rule_hash => rule
  }
}

locals {
# 🔹 Diagnostics locals
# ---------------------
# Purpose:  Collect and group all ingress/egress rules by security group for traceability.
# Used in: Debug output only
# Locals:
# 🔹 sg_rules_by_sg
# Depends on: 🔹 ingress_rules_map, 🔹 egress_rules_map, 🔹 valid_security_group_map
  invalid_security_groups = {
    for sg_key, sg_obj in var.security_groups : sg_key => sg_obj if !contains(keys(var.vpc_config), sg_obj.vpc_id)
  }

  sg_rules_by_sg = {
    for sg_key in keys(local.valid_security_group_map) : 
    sg_key => {
      "00_INGRESS" = [
        for rule in local.ingress_rules_map : "HASH: ${rule.rule_hash} > RULE_SET_REF: ${rule.rule_set_ref} > RULE_SET_DESC: ${rule.description} > PORTS: ${rule.from_port}-${rule.to_port} > SOURCE: ${rule.referenced_security_group_id != null ? rule.referenced_security_group_id : rule.prefix_list_id != null ? rule.prefix_list_id : rule.cidr_ipv4}" if rule.sg_key == sg_key
      ]
      "01_EGRESS" = [
        for rule in local.egress_rules_map : "HASH: ${rule.rule_hash} > RULE_SET_REF: ${rule.rule_set_ref} > RULE_SET_DESC: ${rule.description} > PORTS: ${coalesce(rule.from_port, "NULL")}-${coalesce(rule.to_port, "NULL")} > SOURCE: ${rule.referenced_security_group_id != null ? rule.referenced_security_group_id : rule.prefix_list_id != null ? rule.prefix_list_id : rule.cidr_ipv4}" if rule.sg_key == sg_key
      ]
    }
  }
}

# --------------------------------------------------
# IAM Role, Role Policy Attachment, Instance Profile 
# --------------------------------------------------

locals {

  iam_policy_map = {
    for pol_key, pol_obj in var.iam_policy_config : pol_key => pol_obj
  }

  aws_iam_role_map = {
    for role_key, role_obj in var.iam_role_config : role_key => {
      name                = role_obj.name
      description         = role_obj.description
      assume_role_policy  = jsonencode({
        Version = "2012-10-17"
        Statement = concat(
          length(role_obj.principal.services) > 0 ?
          [{
            Effect    = "Allow"
            Action    = "sts:AssumeRole"
            Principal = {Service = role_obj.principal.services}
          }] : [],
          length(role_obj.principal.accounts) > 0 ?
          [{
            Effect    = "Allow"
            Action    = "sts:AssumeRole"
            Principal = {AWS = role_obj.principal.accounts}
          }] : []
        )
      })
    }
  }

  aws_iam_role_policy_attachment_map = merge([
    for role_key, role_obj in var.iam_role_config : merge(
      {
        for aws_pol_arn in role_obj.aws_managed_policies : "AWS:${role_key}__${split("/", aws_pol_arn)[1]}" => {
          role        = role_key
          policy_arn  = aws_pol_arn
        }
      }, 
      {
        for cust_pol_key in role_obj.custom_managed_policies : "CUST:${role_key}__${cust_pol_key}" => {
          role        = role_key
          policy_arn  = aws_iam_policy.main[cust_pol_key].arn
        } if can(local.iam_policy_map[cust_pol_key]) 
      }
    )
  ]...)

  iam_role_policy_inline = merge([
    for role_key, role_obj in var.iam_role_config : {
      for inline_pol_key, inline_pol_obj in role_obj.inline_policies : "${role_key}__${inline_pol_key}" => {
        name = inline_pol_key
        role = role_key
        policy = jsonencode({
          Version = "2012-10-17"
          Statement = [
            for obj in inline_pol_obj.statement : {
              for k, v in obj : k => v if v != null
            }
          ]
        })
      }
    }
  ]...)

  aws_iam_instance_profile_map = {
    for role_key, role_obj in var.iam_role_config : role_key => {
      name = "PRF__${role_obj.name}"
      role = role_key
    } if role_obj.iam_instance_profile == true
  }
}

# --------------------------------------------------
# CloudWatch Log Groups 
# --------------------------------------------------

locals {
  cloudwatch_log_group_map = {
    for log_grp_obj in var.aws_cloudwatch_log_group_config : "${log_grp_obj.region}__${log_grp_obj.log_namespace_1}__${log_grp_obj.log_namespace_2}__${log_grp_obj.log_namespace_3}" => merge(log_grp_obj, {
      name = "/aws/${log_grp_obj.log_namespace_1}/${log_grp_obj.log_namespace_2}/${log_grp_obj.log_namespace_3}"
    })
  }
}

# --------------------------------------------------
# Flow Logs & Log Destinations
# --------------------------------------------------

locals {

  vpc_flow_logs_merged = {
    for vpc_key, vpc_obj in var.vpc_config : "${vpc_key}__${vpc_obj.flow_logs_config}" => merge(
      var.flow_logs_config[vpc_obj.flow_logs_config],
      {
        att_type    = "vpc"
        vpc_key     = vpc_key
        region  = vpc_obj.region
      }
    ) if vpc_obj.flow_logs_config != null && can(var.flow_logs_config[vpc_obj.flow_logs_config])
  }

  vpc_flow_logs_resolved = {
    for fl_key, fl_obj in local.vpc_flow_logs_merged : fl_key => merge(
      fl_obj,
      fl_obj.log_destination_type == "cloud-watch-logs" ? {
        iam_role_arn        = aws_iam_role.main[fl_obj.iam_role_key].arn
        log_destination_key = "${fl_obj.region}__${fl_obj.log_namespace_1}__${fl_obj.log_namespace_2}__${fl_obj.log_namespace_3}"
        log_group_name      = "/aws/${fl_obj.log_namespace_1}/${fl_obj.log_namespace_2}/${fl_obj.log_namespace_3}"
      } : fl_obj.log_destination_type == "s3" ? {
        iam_role_arn        = null
        log_destination_key = "bucket_key_placeholder"
      } : {
        iam_role_arn        = null
        log_destination_key = "kinesis_key_placeholder"
      }
    )
  }

  subnet_flow_logs_merged = {
    for sn_key, sn_obj in local.subnet_map : "${sn_key}__${sn_obj.flow_logs_config}" => merge(
      var.flow_logs_config[sn_obj.flow_logs_config],
      {
        att_type       = "subnet"
        subnet_key     = sn_key
        region  = sn_obj.region
      }
    ) if sn_obj.flow_logs_config != null && can(var.flow_logs_config[sn_obj.flow_logs_config])
  }

  subnet_flow_logs_resolved = {
    for fl_key, fl_obj in local.subnet_flow_logs_merged : fl_key => merge(
      fl_obj,
      fl_obj.log_destination_type == "cloud-watch-logs" ? {
        iam_role_arn        = aws_iam_role.main[fl_obj.iam_role_key].arn
        log_destination_key = "${fl_obj.region}__${fl_obj.log_namespace_1}__${fl_obj.log_namespace_2}__${fl_obj.log_namespace_3}"
        log_group_name      = "/aws/${fl_obj.log_namespace_1}/${fl_obj.log_namespace_2}/${fl_obj.log_namespace_3}"
      } : fl_obj.log_destination_type == "s3" ? {
        iam_role_arn        = null
        log_destination_key = "bucket_key_placeholder"
      } : {
        iam_role_arn        = null
        log_destination_key = "kinesis_key_placeholder"
      }
    )
  }

  all_flow_logs_resolved = merge(
    local.vpc_flow_logs_resolved, local.subnet_flow_logs_resolved
  )

  cloudwatch_log_groups_map__flow_log__all = { 
    for fl_dst_key in distinct([for fl_obj in local.all_flow_logs_resolved : fl_obj.log_destination_key if fl_obj.log_destination_type == "cloud-watch-logs"]) : fl_dst_key => [for fl_cfg_obj in local.all_flow_logs_resolved : {
      region = fl_cfg_obj.region
      log_group_name = fl_cfg_obj.log_group_name
      retention_in_days = fl_cfg_obj.retention_in_days
    } if fl_cfg_obj.log_destination_key == fl_dst_key][0]
  }

}

# --------------------------------------------------
# AWS Network Firewall Logging Configuration
# --------------------------------------------------

locals {
  aws_networkfirewall_logging_configuration_map = {
    for fw_key, fw_obj in var.fw_config : fw_key => {
      region = fw_obj.region
      logging_config = [
        for log_cfg in fw_obj.logging_config : merge(
          log_cfg,
          log_cfg.log_destination_type == "CloudWatchLogs" ? 
            {log_destination = {logGroup = aws_cloudwatch_log_group.main["${fw_obj.region}__${log_cfg.log_namespace_1}__${fw_key}__${lower(log_cfg.log_type)}"].name}}
          : log_cfg.log_destination_type == "S3" ? 
            {log_destination = {bucketName = "bucketName_Placeholder"}}
          : {log_destination = {deliveryStream = "deliveryStream_Placeholder"}}
        )
      ]
    }
  }
}


