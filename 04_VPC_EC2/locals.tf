# SUBNETS
# -------
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

# IGWs
# ----
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

# NAT GWs & Elastic IPs
# ---------------------
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

# ROUTE TABLES
# ------------
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

# RESOLVED ROUTING INTENT
# -----------------------
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

# REVERSE LOOKUP / SUBNET BY ROUTING POLICY > VPC > AZ
# ----------------------------------------------------
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

# IGW ROUTES
# ----------
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

# VALIDATE SUBNET HAS IGW ROUTE
# -----------------------------
locals {
  subnet_has_igw_route = {
    for rti_key, rti_obj in local.route_table_intent_map :
    rti_obj.subnet_key => "true"
    if rti_obj.routing_policy.inject_igw && can(local.igw_lookup_map[rti_obj.vpc_key])
  }
}

# NAT-GW ROUTES
# -------------
# PRIMARY LOOKUP MAP
# ------------------
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
}

# SECONDARY LOOKUP MAP
# --------------------
locals {
  natgw_lookup_map_by_vpc = {
    for vpc_grp_key in distinct([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key]) :
    vpc_grp_key => [for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_key if nat_gw_obj.vpc_key == vpc_grp_key]
  }
}

# NAT Gateway route plan (AZ-aware with fallback)
# ----------------------------------------------0
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

# ROUTE TABLE ASSOCIATIONS
# ------------------------
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
# DEBUGS // DIAGNOSTICS
# ---------------------

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

#   eni_eips_without_igw_route = [
#     for eip_map_key, eip_map_obj in local.valid_eni_map : eip_map_key 
#     if eip_map_obj.assign_eip && !lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
#   ]

}

# EC2 instances
# -------------
locals {
  # valid_ec2_instance_map_OLD = {
  #   for ec2_key, ec2_obj in var.ec2_config : ec2_key => ec2_obj if (
  #     # contains(keys(ec2_obj.network_interfaces), "nic0") &&
  #     # length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc])) == 1 &&
  #     alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(var.vpc_config), eni_obj.vpc)]) &&
  #     alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(local.subnet_map), "${local.subnet_prefix}${eni_obj.vpc}__${eni_obj.subnet}")])
  #   )
  # }

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


# ELASTIC NETWORK INTERFACES (ENIs)
# ---------------------------------
locals {
  # valid_eni_map = merge([ 
  #   for ec2_key, ec2_obj in local.valid_ec2_instance_map : {for eni_key, eni_obj in ec2_obj.network_interfaces : "${ec2_key}__${eni_key}" => merge(
  #   eni_obj, {
  #     subnet_id       = "${eni_obj.vpc}__${eni_obj.subnet}"
  #     ec2_key         = ec2_key
  #     ec2_nic_key     = eni_key
  #     index           = tonumber(substr(eni_key, length(eni_key) - 1, 1))
  #     security_groups = [for sg in coalesce(eni_obj.security_groups, []) : sg if contains(keys(local.valid_security_group_map), sg)]
  #   },
  #   eni_obj.private_ip_list_enabled == true && eni_obj.private_ip_list != null && length(eni_obj.private_ip_list) > 0 ? 
  #     {
  #       private_ip_list_enabled = eni_obj.private_ip_list_enabled
  #       private_ip_list         = eni_obj.private_ip_list
  #       private_ips_count       = null
  #     } : 
  #   eni_obj.private_ips_count != null && eni_obj.private_ips_count > 0 ? 
  #     {
  #       private_ip_list_enabled = null
  #       private_ip_list         = null
  #       private_ips_count       = eni_obj.private_ips_count
  #     } : 
  #     {
  #       private_ip_list_enabled = null
  #       private_ip_list         = null
  #       private_ips_count       = null
  #     }
  #   )}
  # ]...)
} 

# # ENI ELASTIC IPs
# # ---------------
# locals {
#   valid_eni_eip_map = {
#     for eip_map_key, eip_map_obj in local.valid_eni_map : eip_map_key => {
#       assign_eip            = eip_map_obj.assign_eip
#       subnet_id             = eip_map_obj.subnet_id
#       subnet_has_igw_route  = lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
#       tags                  = eip_map_obj.tags
#     } if eip_map_obj.assign_eip && lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
#   }
# } 

# locals {
#   primary_nic_name = "nic0"
# }

# # Reverse lookup map of ENI keys by EC2 instances
# # -----------------------------------------------
# locals {
#   ec2_eni_lookup_map = {
#     for ec2_key, ec2_obj in local.valid_ec2_instance_map : ec2_key => {
#       for eni_map_key, eni_map_obj in local.valid_eni_map : eni_map_obj.ec2_nic_key => eni_map_key
#       if eni_map_obj.ec2_key == ec2_key
#     }
#   }
# }

# # ENI ATTACHMENTS
# # ---------------
# locals {
#   valid_eni_attachments = {
#     for eni_map_key, eni_map_obj in local.valid_eni_map : eni_map_key => {
#         instance_id           = eni_map_obj.ec2_key
#         network_interface_id  = eni_map_key
#         device_index          = eni_map_obj.index
#       }
#     if eni_map_obj.index > 0
#   } 
# } 


# Prefix Lists
# ------------
locals {
  prefix_list_map = {
    for pl_key, pl_obj in var.prefix_list_config : pl_key => pl_obj 
  }
}

# SECURITY GROUP - VALIDATION
# ---------------------------
# create a new map of VALID security groups from the var.security_group_config map
# Validity is determined by checking the VPC_ID of the security group against keys in VPC_CONFIG data
# - This validated map of security groups is used in all downstream locals
locals {
  valid_security_group_map = {
    for sg_key, sg_obj in var.security_groups : sg_key => sg_obj if contains(keys(var.vpc_config), sg_obj.vpc_id)
  }
}

# SECURITY GROUP RULE AGGREGATION — INGRESS 
# -----------------------------------------
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

# SG EGRESS RULE AGGREGATION
# ---------------------------
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
    # FOR SG RULE DIAGNOSTICS
    sg_in_rules_list_flat = sort([for element in local.ingress_rules_map : "${element.sg_key}-${element.description}-${element.rule_hash}"])

    sg_eg_rules_list_flat = sort([for element in local.egress_rules_map : "${element.sg_key}-${element.description}-${element.rule_hash}"])

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


