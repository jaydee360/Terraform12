# SUBNETS
# -------
# Flattens all subnets across all VPCs into a single map keyed by "vpc_key__subnet_key".
# Each subnet object is enriched with its parent VPC key, its own key, and a resolved AZ name.

# Pseudocode Summary:
# For each VPC in vpc_config:
#   For each subnet in that VPC:
#     - Build a unique key: vpc_key__subnet_key
#     - Merge the original subnet object with:
#         - vpc_key (parent reference)
#         - subnet_key (local identifier)
#         - az (resolved full AZ name via az_lookup)
# Result: A flat map of enriched subnet objects keyed by vpc__subnet
locals {
  subnet_map = merge(
    [for vpc_key, vpc_obj in var.vpc_config :
      { for subnet_key, subnet_obj in vpc_obj.subnets :
        "${vpc_key}__${subnet_key}" => 
          merge(subnet_obj, { 
            vpc_key = "${vpc_key}", 
            subnet_key = "${subnet_key}",
            az = var.az_lookup[var.aws_region][subnet_obj.az]
          })
      }
  ]...)
}

# IGWs
# ----
# multi-step itteration and transformation
# First, extract and enriche IGW definitions from vpc_config, tagging each with its parent VPC key.
# Second, build filtered maps to drive conditional IGW creation and attachment logic.
# Enables modular IGW provisioning based on per-VPC flags, maintaining semantic clarity and operational intent.

# Step 1: Build a flat list of IGW objects from vpc_config
#   - Include only VPCs that define an IGW
#   - Enrich each IGW object with its parent vpc_key
locals {
  igw_list = [
    for vpc_key, vpc_obj in var.vpc_config :
    merge(vpc_obj.igw, { "vpc_key" = "${vpc_key}" }) if vpc_obj.igw != null
  ]
}

# Step 2: Build a map of IGWs to create
#   - From igw_list, include only IGWs where create == true
#   - Keyed by vpc_key
locals {
  igw_create_map = {
    for igw_key, igw_obj in local.igw_list :
    "${igw_obj.vpc_key}" => igw_obj if igw_obj.create
  }
}

# Step 3: Build a map of IGWs to attach
#   - From igw_list, include only IGWs where create == true and attach == true
#   - Keyed by vpc_key
locals {
  igw_attach_map = {
    for igw_key, igw_obj in local.igw_list :
    "${igw_obj.vpc_key}" => igw_obj if igw_obj.attach && igw_obj.create
  }
}

# NAT GWs & Elastic IPs
# ---------------------
# Filters the local.subnet_map above to include only subnets flagged for NAT Gateway provisioning.
# - Include only subnets where has_nat_gw == true
# - Preserve original subnet_key as the map key
# Result: A filtered map of NAT-enabled subnets
locals {
  nat_gw_map = {
    for subnet_key, subnet in local.subnet_map :
    subnet_key => subnet if subnet.has_nat_gw && can(local.igw_attach_map[subnet.vpc_key])
  }
}

# ROUTE TABLES
# ------------
# For each route table entry in route_table_config:
# check if we can access the route_table_key in the subnet_map
# - Merge the original route table object with additional enrichment (attributes lookued up from local.subnet_map):
#   - vpc_key 
#   - subnet_key
#   - az
# Result: A map of enriched route table objects keyed by the "vpc_key__subnet_key" (the same compound as the subnet key)
locals {
  route_table_map = {
    for route_table_key, route_table_object in var.route_table_config : 
    route_table_key => merge(
      route_table_object, 
      {
      "vpc_key"    = local.subnet_map[route_table_key].vpc_key
      "subnet_key" = local.subnet_map[route_table_key].subnet_key
      "az"         = local.subnet_map[route_table_key].az
      }
    ) if can(local.subnet_map[route_table_key])
  } 
}

# IGW ROUTES
# ----------
# Builds a map of IGW routes for route tables flagged with inject_igw.
# For each route table in route_table_map:
# - If inject_igw is true:
#   - Create a route plan entry keyed by "route_table_key__0/0"
#   - Include:
#     - rt_key: the route table key
#     - target_key: the VPC key (also the index of the IGW instance)
#     - destination_prefix: "0.0.0.0/0" (default route)
# Result: A map of IGW route injection plans
locals {
  igw_route_plan = {
    for route_table_key, route_table_object in local.route_table_map : 
    "${route_table_key}__0/0" => {
      "rt_key"  = route_table_key
      "target_key" = route_table_object.vpc_key
      "destination_prefix" = "0.0.0.0/0"
    } if route_table_object.inject_igw && can(local.igw_attach_map[route_table_object.vpc_key])
  }
}

# NAT-GW ROUTES
# -------------
# Proximity-aware NAT routing using PRIMARY and SECONDARY lookups to find the closest NAT Gateway fkr each route_table_object
# Primary lookup:   NAT-GW by VPC & AZ, 
# Secondary lookup: NAT-GW by VPC only (fallback)

# PRIMARY LOOKUP MAP
# Groups NAT Gateway instances by their containing VPC and AZ
# NAT-GW instances are keyed the same as the subnets where they reside.

# Step 1: Extract all unique VPC keys from nat_gw_map
# Step 2: For each VPC key:
# - Step 2a: Extract all unique AZs where NAT Gateways exist for that VPC
# - Step 2b: For each AZ in that VPC:
#   - Step 2b.i: Collect all NAT Gateway instance keys where the NAT Gateway belongs to that VPC and AZ
#   - Step 2b.ii: Store the list of NAT Gateway keys under that AZ
# - Step 2c: Store the AZ-to-NAT-GW map under the current VPC key
# Step 3: Result is a nested map: 
# - nat_gw_by_vpc_az[vpc_key][az] = list of NAT Gateway instance keys

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
# Group NAT Gateway instances by their parent VPC only
# NAT-GW instances are keyed the same as the subnets where they reside.

# Step 1: Extract all VPC keys from nat_gw_map and deduplicate
# Step 2: For each unique VPC key:
# - Collect all NAT Gateway instances with a matching VPC key
# Result: A map of VPC keys to lists of NAT Gateway instance keys
locals {
  nat_gw_by_vpc = {
    for vpc_grp_key in distinct([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key]) :
    vpc_grp_key => [for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_key if nat_gw_obj.vpc_key == vpc_grp_key]
  }
}

# NAT Gateway route plan (AZ-aware with fallback)
# For each route table flagged with inject_nat && where 1 NAT GW exits:
# - Build a route entry for 0.0.0.0/0
# - Attempt to find a NAT Gateway in the same VPC and AZ
# - If none exists, fall back to any NAT Gateway in the same VPC
# - If neither exists, assign an empty list (defensive default)
# - Extract the first NAT Gateway key from the resolved list

locals {
  nat_gw_route_plan = {
    for route_table_key, route_table_object in local.route_table_map : 
    "${route_table_key}__0/0" => {
      "rt_key"  = route_table_key
      "target_key" = try(local.nat_gw_by_vpc_az[route_table_object.vpc_key][route_table_object.az][0], local.nat_gw_by_vpc[route_table_object.vpc_key][0], null)
      "destination_prefix" = "0.0.0.0/0"
    } if route_table_object.inject_nat && can(local.nat_gw_by_vpc[route_table_object.vpc_key][0])
  }
}

# ROUTE TABLE ASSOCIATIONS
# ------------------------
# List of subnets eligible for route table association
# - Subnets flagged with has_route_table == true
# - Subnet key exists in route_table_map

# Step 1: Extract the route table keys from route_table_map
# Step 2: Iterate over each subnet in subnet_map
# Step 3: For each subnet:
# - Check if it has an associated route table (has_route_table == true)
# - Check if its key exists in the extracted route table keys from Step 1
# - If both conditions are met, include the subnet key in the output list
# Step 4: Result is a list of subnet keys eligible for route table association

locals {
  valid_route_table_keys = keys(local.route_table_map)
  valid_subnet_keys = keys(local.subnet_map)

  subnet_route_table_associations = toset([
    for subnet_key, subnet in local.subnet_map : 
    subnet_key if subnet.has_route_table && contains(local.valid_route_table_keys, subnet_key)
  ])
}

locals {

  # FOR DIAGNOSTICS
  # VARIETY OF SCENARIOS

  subnets_without_matching_route_tables = [
    for subnet_key, subnet in local.subnet_map : 
    subnet_key if subnet.has_route_table && !can(local.route_table_map[subnet_key])
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
    route_table_key if route_table_object.inject_igw && !can(local.igw_attach_map[route_table_object.vpc_key])
  ]

  nat_gw_subnets_without_igw = [
    for subnet_key, subnet in local.subnet_map :
    subnet_key if subnet.has_nat_gw && !can(local.igw_attach_map[subnet.vpc_key])
  ]
}

# EC2 instances
# -------------
locals {

#   ec2_instance_map = {
#     for ec2_key, ec2_obj in var.ec2_config : ec2_key => merge(ec2_obj, {subnet_id = "${ec2_obj.vpc}__${ec2_obj.subnet}"})
#   }

/*   reverse_ec2_instances_by_eni_ref = {
    for grp_key in (distinct(flatten([for ec2_key, ec2_obj in var.ec2_config_v2 : 
      [for eni in ec2_obj.eni_refs : eni]]))) : 
    grp_key => [
      for inst_key, inst_obj in var.ec2_config_v2 : inst_key if contains(inst_obj.eni_refs, grp_key)
    ]
  } */

/*   valid_ec2_instance_map = {
    for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key => ec2_obj if 
    length(ec2_obj.eni_refs) > 0 
    &&
    alltrue([for eni in ec2_obj.eni_refs : contains(keys(local.valid_eni_map), eni)]) 
    && 
    alltrue([for eni in ec2_obj.eni_refs : length(local.reverse_ec2_instances_by_eni_ref[eni]) == 1])
  } */

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
/*
  valid_eni_attachments = merge(
    [for ec2_key, ec2_obj in local.valid_ec2_instance_map : 
      {for idx, eni in ec2_obj.eni_refs : "${ec2_key}__${eni}" => {
        attachment_id         = "${ec2_key}__${eni}"
        instance_id           = ec2_key
        network_interface_id  = eni
        device_index          = idx
      } if idx > 0 } 
    ]...
  )
*/

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

/*   valid_eni_map = {
    for eni_key, eni_obj in var.eni_config : eni_key => merge(
      eni_obj, {subnet_id = "${eni_obj.vpc}__${eni_obj.subnet}"},
      eni_obj.private_ip_list_enabled == true && eni_obj.private_ip_list != null && length(eni_obj.private_ip_list) > 0 ? 
      {
        private_ip_list_enabled = eni_obj.private_ip_list_enabled
        private_ip_list = eni_obj.private_ip_list
        private_ips_count = null
      } : 
      eni_obj.private_ips_count != null && eni_obj.private_ips_count > 0 ? 
      {
        private_ip_list_enabled = null
        private_ip_list = null
        private_ips_count = eni_obj.private_ips_count
      } : 
      {
        private_ip_list_enabled = null
        private_ip_list = null
        private_ips_count = null
      }
    ) if contains(keys(local.subnet_map), "${eni_obj.vpc}__${eni_obj.subnet}")
  } */

  valid_eni_map_v2 = merge([ 
    for ec2_key, ec2_obj in local.valid_ec2_instance_map_v2 : {for eni_key, eni_obj in ec2_obj.network_interfaces : "${ec2_key}__${eni_key}" => merge(
    eni_obj, {
      subnet_id   = "${eni_obj.vpc}__${eni_obj.subnet}"
      ec2_key     = ec2_key
      ec2_nic_ref = eni_key
      index       = tonumber(substr(eni_key, length(eni_key) - 1, 1))
    },
    eni_obj.private_ip_list_enabled == true && eni_obj.private_ip_list != null && length(eni_obj.private_ip_list) > 0 ? 
      {
        private_ip_list_enabled = eni_obj.private_ip_list_enabled
        private_ip_list = eni_obj.private_ip_list
        private_ips_count = null
      } : 
    eni_obj.private_ips_count != null && eni_obj.private_ips_count > 0 ? 
      {
        private_ip_list_enabled = null
        private_ip_list = null
        private_ips_count = eni_obj.private_ips_count
      } : 
      {
        private_ip_list_enabled = null
        private_ip_list = null
        private_ips_count = null
      }
    )}
  ]...)

} 

locals {
  subnet_has_igw_route = {
    for route_table_key,  route_table_object in local.route_table_map : 
    route_table_key => "true"
    if route_table_object.inject_igw && can(local.igw_attach_map[route_table_object.vpc_key])
  }
}

locals {

/*   valid_eni_eip_map = {
    for eip_key, eip_obj in local.valid_eni_map : eip_key => {
      assign_eip = eip_obj.assign_eip
      subnet_id = eip_obj.subnet_id
      subnet_has_igw_route = lookup(local.subnet_has_igw_route, eip_obj.subnet_id, false)
    } if eip_obj.assign_eip && lookup(local.subnet_has_igw_route, eip_obj.subnet_id, false)
  } */

  valid_eni_eip_map_v2 = {
    for eip_map_key, eip_map_obj in local.valid_eni_map_v2 : eip_map_key => {
      assign_eip            = eip_map_obj.assign_eip
      subnet_id             = eip_map_obj.subnet_id
      subnet_has_igw_route  = lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
    } if eip_map_obj.assign_eip && lookup(local.subnet_has_igw_route, eip_map_obj.subnet_id, false)
  }

}

locals {
  primary_nic_ref = "nic0"

  ec2_eni_lookup_map = {
    for ec2_key, ec2_obj in local.valid_ec2_instance_map_v2 : ec2_key => {
      for eni_map_key, eni_map_obj in local.valid_eni_map_v2 : eni_map_obj.ec2_nic_ref => eni_map_key
      if eni_map_obj.ec2_key == ec2_key
    }
  }
}


# [for ec2_key, ec2_obj in local.valid_ec2_instance_map_v2 : [for eni_map_key, eni_map_obj in local.valid_eni_map_v2 : eni_map_key if eni_map_obj.ec2_key == ec2_key]]
# {for ec2_key, ec2_obj in local.valid_ec2_instance_map_v2 : ec2_key => {for eni_map_key, eni_map_obj in local.valid_eni_map_v2 : eni_map_obj.ec2_nic_ref => eni_map_key if eni_map_obj.ec2_key == ec2_key}}

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
  hash_exclusions = ["description","ref"]

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


