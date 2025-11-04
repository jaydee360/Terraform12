locals {
  tgw_att_prefix = "TGWATT:"

  tgw_attachment_subnets = {
      for sn_key, sn_obj in local.subnet_map : 
      sn_key => {
          region  = sn_obj.region
          vpc_key = sn_obj.vpc_key
          routing_policy_name = sn_obj.routing_policy
          tgw_key = try(var.routing_policies[sn_obj.routing_policy].tgw_key, null)
      } if startswith(sn_obj.routing_policy, "tgw_attach_")  
      && try(var.routing_policies[sn_obj.routing_policy].tgw_key, null) != null 
      && contains(keys(local.tgw_map), var.routing_policies[sn_obj.routing_policy].tgw_key)
  }

  tgw_att_subnets_by_tgw_vpc = {
      for tgw_grp_key in distinct([for map_obj in local.tgw_attachment_subnets : map_obj.tgw_key]) : tgw_grp_key => {
          for vpc_grp_key in distinct([for map_obj2 in local.tgw_attachment_subnets : map_obj2.vpc_key if map_obj2.tgw_key == tgw_grp_key]) : vpc_grp_key => [
              for sn_key, att_obj in local.tgw_attachment_subnets : sn_key if att_obj.tgw_key == tgw_grp_key && att_obj.vpc_key == vpc_grp_key
          ]
      }
  }

  tgw_attach_map = merge([
      for tgw_key, att_vpcs in local.tgw_att_subnets_by_tgw_vpc : {
          for vpc_key, subnet_list in att_vpcs : "${local.tgw_att_prefix}${tgw_key}__${vpc_key}" => {
              tgw_key     = tgw_key
              vpc_key     = vpc_key
              vpc_region  = var.vpc_config[vpc_key].region
              subnet_keys = subnet_list
          }
      }
  ]...)

  tgw_att_by_tgw_vpc = {
    for tgw_grp_key in distinct([for tgwatt_obj in local.tgw_attach_map : tgwatt_obj.tgw_key]) : tgw_grp_key => {
      for vpc_grp_key in distinct([for tgwatt_obj in local.tgw_attach_map : tgwatt_obj.vpc_key if tgwatt_obj.tgw_key == tgw_grp_key]) : vpc_grp_key => one([
        for tgwatt_key, tgwatt_obj in local.tgw_attach_map : tgwatt_key if tgwatt_obj.tgw_key == tgw_grp_key && tgwatt_obj.vpc_key == vpc_grp_key
      ])
    }  
  }

  tgw_att_cidr = {
    for tgwatt_key, tgwatt_obj in local.tgw_att_by_tgw_vpc : tgwatt_key => {
      for vpcatt_key, vpcatt_obj in tgwatt_obj : vpcatt_key => var.vpc_config[vpcatt_key].vpc_cidr
    }
  }
}

locals {
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

  tgw_rt_assoc_prefix = "__VPCASS:"
  tgw_rt_prop_prefix = "__VPCPROP:"

  tgw_rt_association_map = merge([
    for tgw_rt_key, tgw_rt_obj in local.tgw_rt_map : {
      for vpc_assoc in coalesce(tgw_rt_obj.associations, []) : 
      "${tgw_rt_key}${local.tgw_rt_assoc_prefix}${vpc_assoc}" => {
        region                    = tgw_rt_obj.region
        tgw_key                   = tgw_rt_obj.tgw_key
        tgw_rt_key                = tgw_rt_key
        associated_vpc_name       = vpc_assoc
        associated_vpc_tgw_att_id = local.tgw_att_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_assoc]
      } if can(local.tgw_att_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_assoc])
    } 
  ]...)

  tgw_rt_propagation_map = merge([
    for tgw_rt_key, tgw_rt_obj in local.tgw_rt_map : {
      for vpc_prop in coalesce(tgw_rt_obj.propagations, []) : 
      "${tgw_rt_key}${local.tgw_rt_prop_prefix}${vpc_prop}" => {
        region                    = tgw_rt_obj.region
        tgw_key                   = tgw_rt_obj.tgw_key
        tgw_rt_key                = tgw_rt_key
        propagated_vpc_name       = vpc_prop
        propagated_vpc_tgw_att_id = local.tgw_att_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_prop]
      } if can(local.tgw_att_by_tgw_vpc[tgw_rt_obj.tgw_key][vpc_prop])
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
  nat_gw_route_prefix = "NATGW:"
  nat_gw_route_map = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.nat_gw_route_prefix}${rti_obj.rt_key}" => {
      region              = rti_obj.region
      rt_key  = rti_obj.rt_key
      target_key = try(local.natgw_lookup_map_by_vpc_az[rti_obj.vpc_key][rti_obj.az][0], local.natgw_lookup_map_by_vpc[rti_obj.vpc_key][0], null)
      destination_prefix = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_nat && can(local.natgw_lookup_map_by_vpc[rti_obj.vpc_key][0])
  }
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

