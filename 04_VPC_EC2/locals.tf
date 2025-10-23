# 🔹subnet_map
# ------------
# Purpose: Enriches subnet objects with VPC key and AZ.

# Used in:
# Locals: 🔹 nat_gw_map, 🔹 route_table_map, 🔹 nat_gw_subnets_without_igw_route
# Resources: 🔹 aws_subnet.main, 🔹 aws_nat_gateway.main, 🔹 aws_eip.nat, 🔹aws_route_table_association.main
# Depends on: 🔹 var.vpc_config, 🔹 var.az_lookup
locals {
  subnet_prefix = "SN:"
  subnet_map = merge(
    [for vpc_key, vpc_obj in var.vpc_config :
      {for subnet_key, subnet_obj in vpc_obj.subnets :
        "${local.subnet_prefix}${vpc_key}__${subnet_key}" => merge(
          subnet_obj, { 
            vpc_key = vpc_key, 
            subnet = subnet_key,
            az = var.az_lookup[var.aws_region][subnet_obj.az]
          }
        )
      }
  ]...)
}

# 🔹 igw_map, 🔹 igw_lookup_map
# -----------------------------
# Purpose: Maps IGWs from VPCs and enables reverse lookup of VPCs > IGWs

# Used in:
# Locals: 🔹 igw_route_map, 🔹 subnet_has_igw_route, 🔹 igw_route_plans_without_viable_igw_target
# Resources: 🔹 aws_internet_gateway.main, 🔹 aws_internet_gateway_attachment.main, 🔹 aws_route.igw
# Depends on: 🔹 var.vpc_config
locals {
  igw_prefix = "IGW:"

  igw_map = {
    for vpc_key, vpc_obj in var.vpc_config : 
    "${local.igw_prefix}${vpc_key}" => vpc_key if vpc_obj.create_igw
  }

  igw_lookup_map = {
    for igw_key, vpc_key in local.igw_map : vpc_key => igw_key
  }
}

# 🔹 nat_gw_map
# -------------
# Purpose: Filters subnets eligible for NAT GW creation.

# Used in:
# Locals: 🔹 natgw_lookup_map_by_vpc_az, 🔹 natgw_lookup_map_by_vpc
# Resources: 🔹 aws_nat_gateway.main, 🔹 aws_eip.nat
# Depends on: 🔹 subnet_map, 🔹 subnet_has_igw_route
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

# 🔹 route_table_map
# ------------------
# Purpose: Builds route table objects for subnets with valid routing policies.

# Used in:
# Locals: 🔹 route_table_intent_map, 🔹 subnet_route_table_associations
# Resources: 🔹 aws_route_table.main, 🔹 aws_route_table_association.main
# Depends on: 🔹 subnet_map, 🔹 var.routing_policies
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

# 🔹 route_table_intent_map
# -------------------------
# Purpose: Enriches route tables with routing intent / routing policy metadata.

# Used in:
# Locals: 🔹 subnet_lookup_by_routing_policy_vpc_az, 🔹 igw_route_map, 🔹 nat_gw_route_map, 🔹 subnet_has_igw_route, 🔹 diagnostics
# Resources: 🔹 aws_route.igw, 🔹 aws_route.nat_gw
# Depends on: 🔹 route_table_map, 🔹 var.routing_policies
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

# Step 2: Template stem (route_table_template_refs)
# Sparse map: only RTIs that actually reference templates.
# Just rti_key => [template_names...].

  rti_custom_route_template_refs = {
    for rti_key, rti_obj in local.route_table_intent_map :rti_key => [
      for crt in rti_obj.routing_policy.custom_route_templates : crt
    ] if rti_obj.routing_policy.custom_route_templates != null 
  }

  rti_custom_route_template_expansion = {
    for rti_key, crt_refs in local.rti_custom_route_template_refs : rti_key => [
      for ref in crt_refs : merge(
        lookup(var.custom_route_templates, ref, null),
        {
          rt_key = local.route_table_intent_map[rti_key].rt_key
          vpc_key = local.route_table_intent_map[rti_key].vpc_key
          routing_policy_name = local.route_table_intent_map[rti_key].routing_policy_name
          custom_route_template_name = ref
        }
      )
    ]
  }

    test_crt_routes_1 =  [
      for rti_key, crt_list in local.rti_custom_route_template_expansion : [
        for crt_idx, crt in crt_list : [
          for my_peers in local.vpc_peer_lookup_map[crt.vpc_key] : [
            for peer_idx, peer in my_peers : peer
          ]
        ]
      ]
    ]

    test_crt_routes_2 = {
      for rti_key, crt_list in local.rti_custom_route_template_expansion : rti_key => {
        for crt in crt_list : crt.custom_route_template_name => {
          for peer in local.vpc_peer_lookup_map[crt.vpc_key] : peer.peer_vpc => {
              cidr_block = local.vpc_summary_map[peer.peer_vpc].cidr
              target_type = peer.target_type
              target_key = peer.target_key
            }
          }
        } 
      }

    test_crt_routes_2a = {
      for rti_key, crt_list in local.rti_custom_route_template_expansion : rti_key => {
        for crt in crt_list : crt.custom_route_template_name => [
          for peer in local.vpc_peer_lookup_map[crt.vpc_key] : {
              cidr_block = local.vpc_summary_map[peer.peer_vpc].cidr
              target_type = peer.target_type
              target_key = peer.target_key
            }
          ]
        } 
      }

    test_crt_routes_3 = {
      for rti_key, crt_list in local.rti_custom_route_template_expansion : rti_key => {
        for crt in crt_list : crt.custom_route_template_name => [
          for peer in local.vpc_peer_lookup_map[crt.vpc_key] : {
            cidr_block  = local.vpc_summary_map[peer.peer_vpc].cidr
            target_type = peer.target_type
            target_key  = peer.target_key
          }
        ]
      }
    }

    peering_route_prefix = "PCX:"
    test_crt_routes_4 = {
      for rti_key, crt_list in local.rti_custom_route_template_expansion : "${rti_key}__compound" => merge(flatten([
        for crt in crt_list : [
          for peer in local.vpc_peer_lookup_map[crt.vpc_key] : {
            cidr_block  = local.vpc_summary_map[peer.peer_vpc].cidr
            target_type = peer.target_type
            target_key  = peer.target_key
          }
        ]
      ])...)
    }
        
}

  # route_table_custom_route_expansion = {
  #   for rti_key, rti_obj in local.route_table_intent_map : rti_key => {
  #     rt_key = rti_obj.rt_key
  #     vpc_key = rti_obj.vpc_key
  #     routing_policy = rti_obj.routing_policy
  #   }
  # }

  # route_table_custom_route_expansion_v2 = {
  #   for rti_key, rti_obj in local.route_table_intent_map : rti_key => {
  #     rt_key = rti_obj.rt_key
  #     vpc_key = rti_obj.vpc_key
  #     routing_policy = merge(
  #       rti_obj.routing_policy,
  #       rti_obj.routing_policy.custom_route_templates != null ? [for crt in rti_obj.routing_policy.custom_route_templates : lookup(var.custom_route_templates, crt, null)] : [] 
  #     )
  #   }
  # }

  # test = {for rti_key, rti_obj in local.route_table_intent_map : rti_key => [for crt in rti_obj.routing_policy.custom_route_templates : crt] if rti_obj.routing_policy.custom_route_templates != null }
  
  # {
  #   for rti_key, rti_obj in local.route_table_intent_map : 
  #   rti_key => [
  #     for crt in rti_obj.routing_policy.custom_route_templates : lookup(var.custom_route_templates, crt, null)
  #   ] if rti_obj.routing_policy.custom_route_templates != null 
  # }

  #   {for rti_key, rti_obj in local.route_table_intent_map : 
  #   rti_key => {
  #     for crt in rti_obj.routing_policy.custom_route_templates : "custom_route_templates" => lookup(var.custom_route_templates, crt, null)
  #    } if rti_obj.routing_policy.custom_route_templates != null 
  #   }

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

# 🔹 igw_route_map
# ----------------
# Purpose: Plans IGW routes for route tables with IGW routing intent.

# Used in:
# Resources: 🔹 aws_route.igw
# Depends on: 🔹 route_table_intent_map, 🔹 igw_lookup_map
locals {
  igw_route_prefix = "IGW:"

  igw_route_map = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.igw_route_prefix}${rti_obj.rt_key}" => {
      rt_key              = rti_obj.rt_key
      target_key          = local.igw_lookup_map[rti_obj.vpc_key]
      destination_prefix  = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_igw && can(local.igw_lookup_map[rti_obj.vpc_key])
  }
}

# 🔹 subnet_has_igw_route
# -----------------------
# Purpose: Flags subnets with viable IGW routing.

# Used in:
# Locals: 🔹 nat_gw_map, 🔹 valid_eni_eip_map, 🔹 diagnostics
# Resources: indirectly via 🔹 aws_eip.nat, 🔹 aws_eip.eni
# Depends on: 🔹 route_table_intent_map, 🔹 igw_lookup_map
locals {
  subnet_has_igw_route = {
    for rti_key, rti_obj in local.route_table_intent_map :
    rti_obj.subnet_key => "true"
    if rti_obj.routing_policy.inject_igw && can(local.igw_lookup_map[rti_obj.vpc_key])
  }
}

# 🔹 natgw_lookup_map_by_vpc_az, 🔹 natgw_lookup_map_by_vpc
# ---------------------------------------------------------
# Purpose: Enables NAT GW targeting (VPC > AZ > NAT GW) and (VPC > NAT GW)

# Used in:
# Locals: 🔹 nat_gw_route_map, 🔹 diagnostics
# Resources: indirectly via 🔹 aws_route.nat_gw
# Depends on: 🔹 nat_gw_map
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

# 🔹 nat_gw_route_map
# --------------------
# Purpose: Plans NAT GW routes with AZ-aware fallback.

# Used in:
# Resources: 🔹 aws_route.nat_gw
# Depends on: 🔹 route_table_intent_map, 🔹 NAT GW lookup maps
locals {
  nat_gw_route_prefix = "NATGW:"
  
  nat_gw_route_map = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.nat_gw_route_prefix}${rti_obj.rt_key}" => {
      rt_key  = rti_obj.rt_key
      target_key = try(local.natgw_lookup_map_by_vpc_az[rti_obj.vpc_key][rti_obj.az][0], local.natgw_lookup_map_by_vpc[rti_obj.vpc_key][0], null)
      destination_prefix = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_nat && can(local.natgw_lookup_map_by_vpc[rti_obj.vpc_key][0])
  }
}

# 🔹 subnet_route_table_associations
# ----------------------------------
# Purpose: Maps subnets to route tables for association.

# Used in:
# Resources: 🔹 aws_route_table_association.main
# Depends on: 🔹 route_table_map
locals {
  rt_assoc_prefix = "RTASS:"

  subnet_route_table_associations = {
    for rt_key, rt_obj in local.route_table_map : 
    "${local.rt_assoc_prefix}${rt_key}" => {
      subnet_id       = rt_obj.subnet_key
      route_table_id  = rt_key
    }
  }
}

locals {
# 🔹 Diagnostics locals
# ---------------------
# Purpose: Surface misconfigurations or missing dependencies.
# Used in: Debug output only
# Locals:
# 🔹 nat_gw_subnets_without_igw_route
# 🔹 igw_route_plans_without_viable_igw_target
# 🔹 nat_gw_route_plans_without_viable_nat_gw_target
# 🔹 subnets_not_in_subnet_route_table_association
# 🔹 eni_eips_without_igw_route

  nat_gw_subnets_without_igw_route = [
    for subnet_key, subnet in local.subnet_map :
    subnet_key if subnet.create_natgw && !can(local.subnet_has_igw_route[subnet_key])
  ]

  igw_route_plans_without_viable_igw_target = [
    for rti_key, rti_obj in local.route_table_intent_map : 
    "VPC: ${rti_obj.vpc_key} > SUBNET: ${rti_obj.subnet_key} > ROUTING_POLICY: ${rti_obj.routing_policy_name}" 
    if rti_obj.routing_policy.inject_igw && !can(local.igw_lookup_map[rti_obj.vpc_key])
  ]

  nat_gw_route_plans_without_viable_nat_gw_target = [
    for rti_key, rti_obj in local.route_table_intent_map :
    "VPC: ${rti_obj.vpc_key} > SUBNET: ${rti_obj.subnet_key} > ROUTING_POLICY: ${rti_obj.routing_policy_name}" 
    if rti_obj.routing_policy.inject_nat && !can(local.natgw_lookup_map_by_vpc[rti_obj.vpc_key][0])
  ]

  subnets_not_in_subnet_route_table_association = [
    for sn in keys(local.subnet_map) : sn 
    if !contains([for ass in local.subnet_route_table_associations : ass.subnet_id], sn)
  ]

  eni_eips_without_igw_route = [
    for eip_map_key, eip_map_obj in local.valid_eni_map : eip_map_key 
    if eip_map_obj.assign_eip && !lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
  ]
}

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
        network_interfaces = {for nic_key in distinct(concat(
          keys(try(var.ec2_profiles[inst_obj.ec2_profile].network_interfaces, {})),
          keys(inst_obj.network_interfaces))) : nic_key => merge(
            try(var.ec2_profiles[inst_obj.ec2_profile].network_interfaces[nic_key], {}),
            {
              for key, value in try(inst_obj.network_interfaces[nic_key], {}) : key => value if value != null
            },
            {
              az = try(var.az_lookup[var.aws_region][try(inst_obj.network_interfaces[nic_key].az, null)], null)
            }
          )
        }
      }
    )
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
      # contains(keys(ec2_obj.network_interfaces), "nic0") &&
      # length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc])) == 1 &&
      alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : can(contains(keys(var.vpc_config), eni_obj.vpc))]) &&
      alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : can(contains(keys(local.subnet_map), eni_obj.subnet_id))])
    )
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
  valid_eni_map = merge([ 
    for ec2_key, ec2_obj in local.valid_ec2_instance_map : {for eni_key, eni_obj in ec2_obj.network_interfaces : "${ec2_key}__${eni_key}" => merge(
      eni_obj, {
        # subnet_id       = "${eni_obj.vpc}__${eni_obj.subnet}"
        ec2_key         = ec2_key
        ec2_nic_key     = eni_key
        index           = tonumber(substr(eni_key, length(eni_key) - 1, 1))
        security_groups = [for security_group  in coalesce(eni_obj.security_groups, []) : security_group  if contains(keys(local.valid_security_group_map), security_group)]
        tags            = ec2_obj.tags
      }
    )}
  ]...)

enis_with_invalid_sgs = merge([
  for ec2_key, ec2_obj in local.valid_ec2_instance_map : {
    for eni_key, eni_obj in ec2_obj.network_interfaces : 
    "${ec2_key}__${eni_key}" => setsubtract(
      eni_obj.security_groups, ([
        for security_group  in coalesce(eni_obj.security_groups, []) : security_group if contains(keys(local.valid_security_group_map), security_group)
      ])
    ) if length(setsubtract(
      eni_obj.security_groups, ([for security_group  in coalesce(eni_obj.security_groups, []) : security_group if contains(keys(local.valid_security_group_map), security_group)])
    )) > 0
  }
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
  valid_security_group_map = {
    for sg_key, sg_obj in var.security_groups : sg_key => sg_obj if contains(keys(var.vpc_config), sg_obj.vpc_id)
  }
}

# 🔹 normalised_ingress_ref_rules, hashed_ingress_rules, ingress_rules_map
# ------------------------------------------------------------------------
# Purpose: Normalize, hash, deduplicate and map ingress rules.

# Used in:
# Locals: 🔹 hashed_ingress_rules, 🔹 ingress_rules_map
# Resources: 🔹 aws_vpc_security_group_ingress_rule.main
# Depends on: 🔹 valid_security_group_map, var.security_group_rule_sets, 🔹 local.hash_exclusions
locals {
  
  hash_exclusions = ["description", "rule_set_ref", "tags"]

  # NORMALISATION & ENRICHMENT (REFERENCED RULES - INGRESS)
  # -------------------------------------------------------
  normalised_ingress_ref_rules = flatten([
    for sg_key, sg_obj in local.valid_security_group_map : [for rule_set in sg_obj.ingress_ref : [for rule in var.security_group_rule_sets[rule_set] : merge(
      rule,
      (rule.referenced_security_group_id != null) ? {
        referenced_security_group_id  = rule.referenced_security_group_id
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : (rule.prefix_list_id != null) ? {
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
      (rule.referenced_security_group_id != null) ? {
        referenced_security_group_id  = rule.referenced_security_group_id
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : (rule.prefix_list_id != null) ? {
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
# Purpose: Flatten and group ingress/egress rules for traceability and diagnostics.
# Used in: Debug output only
# Locals:
# 🔹 sg_in_rules_list_flat
# 🔹 sg_eg_rules_list_flat
# 🔹 sg_in_rules_by_sg
# 🔹 sg_eg_rules_by_sg
# Depends on: 🔹 ingress_rules_map, 🔹 egress_rules_map, 🔹 valid_security_group_map

  sg_in_rules_list_flat = sort(
    [for element in local.ingress_rules_map : "${element.sg_key}-${element.description}-${element.rule_hash}"]
  )

  sg_eg_rules_list_flat = sort(
    [for element in local.egress_rules_map : "${element.sg_key}-${element.description}-${element.rule_hash}"]
  )

  sg_in_rules_by_sg = {
    for sg_key in keys(local.valid_security_group_map) :
    sg_key => [
      for rule in local.ingress_rules_map : "${rule.rule_hash}-DESC:${rule.description}-REF:${rule.rule_set_ref}" if rule.sg_key == sg_key
    ]
  }

  sg_eg_rules_by_sg = {
    for sg_key in keys(local.valid_security_group_map) :
    sg_key => [
      for rule in local.egress_rules_map : "${rule.rule_hash}-DESC:${rule.description}-REF:${rule.rule_set_ref}" if rule.sg_key == sg_key
    ]
  }
}

