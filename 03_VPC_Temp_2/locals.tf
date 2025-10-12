# SUBNETS
# -------
locals {
  subnet_map = merge(
    [for vpc_key, vpc_obj in var.vpc_config :
      { for subnet_key, subnet_obj in vpc_obj.subnets :
        "${vpc_key}__${subnet_key}" => 
          merge(subnet_obj, { 
            vpc_key = vpc_key, 
            subnet_key = subnet_key,
            az = var.az_lookup[var.aws_region][subnet_obj.az]
          })
      }
  ]...)
}

# IGWs
# ----
locals {
  igw_prefix = "IGW:"

  igw_list = [
    for vpc_key, vpc_obj in var.vpc_config :
    merge(vpc_obj.igw, { vpc_key = vpc_key }) if vpc_obj.igw != null
  ]

  igw_create_map = {
    for igw_key, igw_obj in local.igw_list :
    "${local.igw_prefix}${igw_obj.vpc_key}" => igw_obj if igw_obj.create
  }

  igw_attach_map = {
    for igw_key, igw_obj in local.igw_list :
    "${local.igw_prefix}${igw_obj.vpc_key}" => igw_obj if igw_obj.attach && igw_obj.create
  }

# Create a reverse lookup map of VPC KEY => IGW KEY to allow IGW lookup by VPC
  vpc_to_igw_lookup_map = {
    for key, obj in local.igw_attach_map :
    obj.vpc_key => key
  }
}

# NAT GWs & Elastic IPs
# ---------------------
locals {
  nat_gw_prefix = "NATGW:"

  nat_gw_map = {
    for subnet_key, subnet in local.subnet_map :
    "${local.nat_gw_prefix}${subnet_key}" => merge(
        subnet, 
        {subnet_id = "${subnet.vpc_key}__${subnet.subnet_key}"}
      ) if subnet.create_nat_gw && lookup(local.subnet_has_igw_route, subnet_key, false)
  }
}

# ROUTE TABLES
# ------------
locals {
  rt_prefix = "RT:"

  route_table_map = {
    for subnet_key, subnet_obj in local.subnet_map : 
    "${local.rt_prefix}${subnet_key}" => merge(
      subnet_obj,
      {subnet_map_key = subnet_key}
    ) if (subnet_obj.routing_policy != null && contains(keys(var.routing_policies), subnet_obj.routing_policy)) || (subnet_obj.override_routing_policy && contains(keys(var.route_table_config), subnet_key))
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
      (rt_obj.override_routing_policy && contains(keys(var.route_table_config), rt_obj.subnet_map_key)) ?
      {
        rt_key              = rt_key
        routing_policy_name = "OVERIDE"
        routing_policy      = lookup(var.route_table_config, rt_obj.subnet_map_key, null)
      } : 
      {
        rt_key              = rt_key
        routing_policy_name = rt_obj.routing_policy
        routing_policy      = lookup(var.routing_policies, rt_obj.routing_policy, null)
      }
    ) 
  }
}

# IGW ROUTES
# ----------
locals {
  igw_route_prefix = "IGW:"

  igw_route_plan = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.igw_route_prefix}${rti_obj.rt_key}" => {
      rt_key              = rti_obj.rt_key
      target_key          = local.vpc_to_igw_lookup_map[rti_obj.vpc_key]
      destination_prefix  = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_igw && can(local.vpc_to_igw_lookup_map[rti_obj.vpc_key])
  }
}

# VALIDATE SUBNET HAS IGW ROUTE
# -----------------------------
locals {
  subnet_has_igw_route = {
    for rti_key, rti_obj in local.route_table_intent_map :
    rti_obj.subnet_map_key => "true"
    if rti_obj.routing_policy.inject_igw && can(local.vpc_to_igw_lookup_map[rti_obj.vpc_key])
  }
}

# NAT-GW ROUTES
# -------------
# PRIMARY LOOKUP MAP
locals {
  nat_gw_by_vpc_az = {
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
locals {
  nat_gw_by_vpc = {
    for vpc_grp_key in distinct([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key]) :
    vpc_grp_key => [for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_key if nat_gw_obj.vpc_key == vpc_grp_key]
  }
}

# NAT Gateway route plan (AZ-aware with fallback)
locals {
  nat_gw_route_prefix = "NATGW:"
  
  nat_gw_route_plan = {
    for rti_key, rti_obj in local.route_table_intent_map : 
    "${local.nat_gw_route_prefix}${rti_obj.rt_key}" => {
      rt_key  = rti_obj.rt_key
      target_key = try(local.nat_gw_by_vpc_az[rti_obj.vpc_key][rti_obj.az][0], local.nat_gw_by_vpc[rti_obj.vpc_key][0], null)
      destination_prefix = "0.0.0.0/0"
    } if rti_obj.routing_policy.inject_nat && can(local.nat_gw_by_vpc[rti_obj.vpc_key][0])
  }
}

# ROUTE TABLE ASSOCIATIONS
# ------------------------
locals {
  rt_assoc_prefix = "RTASS:"

  subnet_route_table_associations = {
    for rt_key, rt_obj in local.route_table_map : 
    "${local.rt_assoc_prefix}${rt_key}" => {
      subnet_id       = rt_obj.subnet_map_key
      route_table_id  = rt_key
    } if rt_obj.associate_routing_policy
  }
}

/* locals {
  # FOR DIAGNOSTICS
  # VARIETY OF SCENARIOS

  subnets_without_matching_route_tables = [
    for subnet_key, subnet in local.subnet_map : 
    subnet_key if subnet.associate_route_table && !can(local.route_table_map[subnet_key])
  ]

  unused_route_tables_without_matching_subnet = [
    for route_table_key, route_table_object in var.route_table_config : 
    route_table_key if !can(local.subnet_map[route_table_key])
  ]

  nat_gw_route_plans_without_viable_nat_gw_target = [
    for route_table_key, route_table_object in local.route_table_map : 
    route_table_key if route_table_object.inject_nat && !can(local.nat_gw_by_vpc[route_table_object.vpc_key][0])
  ]

  igw_route_plans_without_viable_igw_target = [
    for route_table_key, route_table_object in local.route_table_map : 
    route_table_key if route_table_object.inject_igw && !can(local.vpc_to_igw_lookup_map[route_table_object.vpc_key])
  ]

  nat_gw_subnets_without_igw = [
    for subnet_key, subnet in local.subnet_map :
    subnet_key if subnet.create_nat_gw && !can(local.subnet_has_igw_route[subnet_key])
  ]
}
 */
# EC2 instances
# -------------
locals {
  valid_ec2_instance_map_v2 = {
    for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key => ec2_obj if (
      # contains(keys(ec2_obj.network_interfaces), "nic0") &&
      # length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc])) == 1 &&
      alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(var.vpc_config), eni_obj.vpc)]) &&
      alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(local.subnet_map), "${eni_obj.vpc}__${eni_obj.subnet}")])
    )
  }
}

# ENI ATTACHMENTS
# ---------------
locals {
  valid_eni_attachments_v2 = {
    for eni_map_key, eni_map_obj in local.valid_eni_map_v2 : eni_map_key => {
        instance_id           = eni_map_obj.ec2_key
        network_interface_id  = eni_map_key
        device_index          = eni_map_obj.index
      }
    if eni_map_obj.index > 0
  } 
} 



# ELASTIC NETWORK INTERFACES (ENIs)
# ---------------------------------
locals {
  valid_eni_map_v2 = merge([ 
    for ec2_key, ec2_obj in local.valid_ec2_instance_map_v2 : {for eni_key, eni_obj in ec2_obj.network_interfaces : "${ec2_key}__${eni_key}" => merge(
    eni_obj, {
      subnet_id       = "${eni_obj.vpc}__${eni_obj.subnet}"
      ec2_key         = ec2_key
      ec2_nic_ref     = eni_key
      index           = tonumber(substr(eni_key, length(eni_key) - 1, 1))
      security_groups = [for sg in coalesce(eni_obj.security_groups, []) : sg if contains(keys(local.valid_security_group_map), sg)]
    },
    eni_obj.private_ip_list_enabled == true && eni_obj.private_ip_list != null && length(eni_obj.private_ip_list) > 0 ? 
      {
        private_ip_list_enabled = eni_obj.private_ip_list_enabled
        private_ip_list         = eni_obj.private_ip_list
        private_ips_count       = null
      } : 
    eni_obj.private_ips_count != null && eni_obj.private_ips_count > 0 ? 
      {
        private_ip_list_enabled = null
        private_ip_list         = null
        private_ips_count       = eni_obj.private_ips_count
      } : 
      {
        private_ip_list_enabled = null
        private_ip_list         = null
        private_ips_count       = null
      }
    )}
  ]...)
} 

locals {
  valid_eni_eip_map_v2 = {
    for eip_map_key, eip_map_obj in local.valid_eni_map_v2 : eip_map_key => {
      assign_eip            = eip_map_obj.assign_eip
      subnet_id             = eip_map_obj.subnet_id
      subnet_has_igw_route  = lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
    } if eip_map_obj.assign_eip && lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
  }
} 


locals {
  primary_nic_name = "nic0"

  ec2_eni_lookup_map = {
    for ec2_key, ec2_obj in local.valid_ec2_instance_map_v2 : ec2_key => {
      for eni_map_key, eni_map_obj in local.valid_eni_map_v2 : eni_map_obj.ec2_nic_ref => eni_map_key
      if eni_map_obj.ec2_key == ec2_key
    }
  }
}

#
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
    for sg_key, sg_obj in var.security_group_config : sg_key => sg_obj if contains(keys(var.vpc_config), sg_obj.vpc_id)
  }
}

# SECURITY GROUP RULE AGGREGATION — INGRESS 
# -----------------------------------------
# This locals blocks constructs unified, deduplicated maps of all ingress rules across valid security groups.
# It supports both inline rule definitions and references to shared rule definition as an override.
#
# Normalisation & Enrichment:
# - Each rule is resolved to one of three target types:
#     - referenced_security_group_id
#     - prefix_list_id
#     - cidr_ipv4
# - Each rule is enriched with
#     - sg_key: the parent SG it belongs to
#     - ref: true if the rule references shared_security_group_rules
#
# Hashing:
# - Each rule is further enriched with:
#     - rule_hash: a unique fingerprint for deduplication
#       - Computed from the normalized rule, excluding metadata fields (e.g. description)
#       - Exclusion list is defined in local.hash_exclusions
#
# Aggregation:
# - Combines inline and referenced rules into a single flat list
# - Deduplicates the combined list using rule_hash and builds a map keyed by hash
#
# This structure ensures:
# - Canonical resolution of rule targets
# - Traceability to source SG and rule origin
# - Deduplication integrity across inline and shared rules
# - Clean, deterministic resource creation

locals {
  hash_exclusions = ["description", "ref", "tags"]

  # NORMALISATION & ENRICHMENT (INLINE RULES - INGRESS)
  # ---------------------------------------------------
  normalised_inline_ingress_rules = flatten([
    for sg_key, sg_obj in local.valid_security_group_map : (sg_obj.ingress_ref == null && sg_obj.ingress != null) ?
    [for rule in sg_obj.ingress : merge(rule, (
      (rule.referenced_security_group_id != null && contains(keys(local.valid_security_group_map), rule.referenced_security_group_id)) ? {
        # does not cuurent check the validity
        referenced_security_group_id  = rule.referenced_security_group_id
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : 
      rule.prefix_list_id != null && contains(keys(local.prefix_list_map), rule.prefix_list_id) ? {
        referenced_security_group_id  = null
        # does not cuurent check the validity
        prefix_list_id                = rule.prefix_list_id
        cidr_ipv4                     = null
      } : {
        referenced_security_group_id  = null
        prefix_list_id                = null
        cidr_ipv4                     = rule.cidr_ipv4        
      }), 
      {
        sg_key  = sg_key
        ref     = false      
      })
    ] : []
  ])

  # NORMALISATION & ENRICHMENT (REFERENCED RULES - INGRESS)
  # -------------------------------------------------------
  normalised_referenced_ingress_rules = flatten([
    for sg_key, sg_obj in local.valid_security_group_map : (sg_obj.ingress_ref != null && can(var.shared_security_group_rules[sg_obj.ingress_ref].ingress)) ?
    [for rule in var.shared_security_group_rules[sg_obj.ingress_ref].ingress : merge(rule, (
      (rule.referenced_security_group_id != null && contains(keys(local.valid_security_group_map), rule.referenced_security_group_id)) ? {
        # does not cuurent check the validity
        referenced_security_group_id  = rule.referenced_security_group_id
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : 
      rule.prefix_list_id != null && contains(keys(local.prefix_list_map), rule.prefix_list_id) ? {
        referenced_security_group_id  = null
        # does not cuurent check the validity
        prefix_list_id                = rule.prefix_list_id
        cidr_ipv4                     = null
      } : {
        referenced_security_group_id  = null
        prefix_list_id                = null
        cidr_ipv4                     = rule.cidr_ipv4        
      }), 
      {
        sg_key  = sg_key
        ref     = true      
      })
    ] : []
  ])

  # HASHING (INGRESS)
  # -----------------
  hashed_inline_ingress_rules = flatten([
    for rule in local.normalised_inline_ingress_rules : merge(rule, {
      rule_hash = md5(jsonencode({for key, value in rule : key => value if !contains(local.hash_exclusions, key)}))
    })
  ])

  hashed_referenced_ingress_rules = flatten([
    for rule in local.normalised_referenced_ingress_rules : merge(rule, {
      rule_hash = md5(jsonencode({for key, value in rule : key => value if !contains(local.hash_exclusions, key)}))
    })
  ])

  # AGGREGATION (INGRESS)
  # ---------------------
  # Combine inline and referenced ingress rules into a single list
  # - Flattening ensures a uniform structure for downstream use
  all_ingress_rules = flatten([[for rule in local.hashed_inline_ingress_rules : rule], [for rule in local.hashed_referenced_ingress_rules : rule]])

  # Build a map of unique ingress rules keyed by rule_hash
  # - Ensures deduplication and traceability
  # This map is used to create the actual 'aws_vpc_security_group_ingress_rule' resource
  ingress_rules_map = {
    for rule in distinct(local.all_ingress_rules) :
    rule.rule_hash => rule
  }
}

# SG EGRESS RULE AGGREGATION
# ---------------------------
# This block collects all egress rules—both inline and shared—into a unified, deduplicated map.
# detailed comments are ommitted because the logic and purpose are identical to those of INGRESS RULE AGGREGATION
# the egress lists are used instead of ingress

locals {
  # NORMALISATION & ENRICHMENT (INLINE RULES - EGRESS)
  # --------------------------------------------------
  normalised_inline_egress_rules = flatten([
    for sg_key, sg_obj in local.valid_security_group_map : (sg_obj.egress_ref == null && sg_obj.egress != null) ?
    [for rule in sg_obj.egress : merge(rule, (
      (rule.referenced_security_group_id != null && contains(keys(local.valid_security_group_map), rule.referenced_security_group_id)) ? {
        # does not cuurent check the validity        
        referenced_security_group_id  = rule.referenced_security_group_id
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : 
      rule.prefix_list_id != null && contains(keys(local.prefix_list_map), rule.prefix_list_id) ? {
        referenced_security_group_id  = null
        # does not cuurent check the validity
        prefix_list_id                = rule.prefix_list_id
        cidr_ipv4                     = null
      } : {
        referenced_security_group_id  = null
        prefix_list_id                = null
        cidr_ipv4                     = rule.cidr_ipv4        
      }), {sg_key = sg_key})
    ] : []
  ])

  # NORMALISATION & ENRICHMENT (REFERENCED RULES - EGRESS)
  # ------------------------------------------------------
  normalised_referenced_egress_rules = flatten([
    for sg_key, sg_obj in local.valid_security_group_map : (sg_obj.egress_ref != null && can(var.shared_security_group_rules[sg_obj.egress_ref].egress)) ?
    [for rule in var.shared_security_group_rules[sg_obj.egress_ref].egress : merge(rule, (
      (rule.referenced_security_group_id != null && contains(keys(local.valid_security_group_map), rule.referenced_security_group_id)) ? {
        # does not cuurent check the validity
        referenced_security_group_id  = rule.referenced_security_group_id
        prefix_list_id                = null
        cidr_ipv4                     = null
      } : 
      rule.prefix_list_id != null && contains(keys(local.prefix_list_map), rule.prefix_list_id) ? {
        referenced_security_group_id  = null
        # does not cuurent check the validity
        prefix_list_id                = rule.prefix_list_id
        cidr_ipv4                     = null
      } : {
        referenced_security_group_id  = null
        prefix_list_id                = null
        cidr_ipv4                     = rule.cidr_ipv4        
      }), {sg_key = sg_key})
    ] : []
  ])

  # HASHING (EGRESS)
  # ----------------
  hashed_inline_egress_rules = flatten([
    for rule in local.normalised_inline_egress_rules : merge(rule, {
      rule_hash = md5(jsonencode({for key, value in rule : key => value if !contains(local.hash_exclusions, key)}))
      ref       = false
    })
  ])

  hashed_referenced_egress_rules = flatten([
    for rule in local.normalised_referenced_egress_rules : merge(rule, {
      rule_hash = md5(jsonencode({for key, value in rule : key => value if !contains(local.hash_exclusions, key)}))
      ref       = true
    })
  ])

  # AGGREGATION (INGRESS)
  # ---------------------
  all_egress_rules = flatten([[for rule in local.hashed_inline_egress_rules : rule], [for rule in local.hashed_referenced_egress_rules : rule]])

  egress_rules_map = {
    for rule in distinct(local.all_egress_rules) :
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
        for rule in local.ingress_rules_map : "${rule.rule_hash}-DESC:${rule.description}-REF:${rule.ref}" if rule.sg_key == sg_key
      ]
    }

    sg_eg_rules_by_sg = {
      for sg_key in keys(local.valid_security_group_map) :
      sg_key => [
        for rule in local.egress_rules_map : "${rule.rule_hash}-DESC:${rule.description}-REF:${rule.ref}" if rule.sg_key == sg_key
      ]
    }
}


