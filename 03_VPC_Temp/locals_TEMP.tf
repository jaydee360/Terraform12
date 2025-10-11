

/* 
# simple list and map reproduction: OUTER to loop through the instances, and INNER to loop through the NICs
[for ec2_key, ec2_obj in var.ec2_config_v2 : [for eni_key, eni_obj in ec2_obj.network_interfaces : "${ec2_key} ---> ${eni_key} / ${eni_obj.vpc} / ${eni_obj.subnet}"]]
{for ec2_key, ec2_obj in var.ec2_config_v2 : "OUTER-LOOP: ${ec2_key}" => [for eni_key, eni_obj in ec2_obj.network_interfaces : "INNER-LOOP: ${ec2_key} ---> ${eni_key} / ${eni_obj.vpc} / ${eni_obj.subnet}"]}

# Prototype expression to test for the presence of nic0 in the keys of nested network interfaces map
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if contains(keys(ec2_obj.network_interfaces), "nic0")]

# Prototype expression to output distinct vpc on each instance network interfaces
[for ec2_key, ec2_obj in var.ec2_config_v2 : "DISTINCT VPCs in ${ec2_key} NICs = ${length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc]))}"]

# Prototype expression to test & filter results if no more than 1 distinct vpc on the network interfaces
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if length(distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc])) == 1]

# get a list of VPCs accross ec2 instance network interfaces
flatten([for ec2_key, ec2_obj in var.ec2_config_v2 : distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc])])

# get a list of instance, nics and VPCs accross the FIRST network interfaces (with and without narration)
[for ec2_key, ec2_obj in var.ec2_config_v2 : [for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc][0]]
[for ec2_key, ec2_obj in var.ec2_config_v2 : "${ec2_key}-->${[for eni_key, eni_obj in ec2_obj.network_interfaces : "${eni_key}->${eni_obj.vpc}"][0]}"]

# Pseudocode to check that each network inteface vpc exists in vpc_config
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if [<EACH NIC> contains(keys(var.vpc_config), <VALUE>)]]
# First attempt at realisation 
# this give error: "The 'if' clause value is invalid: bool required, but have tuple."
# shows that the innter loop is returning mutliple booleans, for one for each NIC evaluated
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if [for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(var.vpc_config), eni_obj.vpc)]]

# If we wrap the inner loop in an alltrue(), then it works 
# This checks for each EC2 instance: all NICs VPC refs are valid against var.vpc_config
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(var.vpc_config), eni_obj.vpc)])]

# This is a way of testing the VPC reference only on the first item [0] from the collection of NICs
# We can consider this test reliabe if we know that there is only 1 distinct VPC ref accross all NICs (e.g. they are all the same, so it doesnt matter which one we test)
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if contains(keys(var.vpc_config), [for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc][0])]

# This was an attempt to use distinct VPC references, but distinct returns a list, where the contains() function expects a single value.
# Result: Nothing is matched and the expression returns only an empty list
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if contains(keys(var.vpc_config), distinct([for eni_key, eni_obj in ec2_obj.network_interfaces : eni_obj.vpc]))]

# this checks each EC2 instance: that all SUBNET refs on all NICs are valid against local.subnet_map.
# it reconstructs the correct compound key from vpc__subnet
[for ec2_key, ec2_obj in var.ec2_config_v2 : ec2_key if alltrue([for eni_key, eni_obj in ec2_obj.network_interfaces : contains(keys(local.subnet_map), "${eni_obj.vpc}__${eni_obj.subnet}")])]

# these were experiments in testing contains with a literal lookup
var.ec2_config_v2["web_01"].network_interfaces["nic0"].vpc
contains(keys(var.vpc_config), var.ec2_config_v2["web_01"].network_interfaces["nic0"].vpc)
*/

# valid ENI map from ec2_config
# [ for k, o in local.valid_ec2_instance_map_v2 : {for kk, oo in o.network_interfaces : kk => oo} ]

/* locals {
  sg_map = {
    for sg_key, sg_obj in var.security_group_config : sg_key => sg_obj if can(var.vpc_config[sg_obj.vpc_id])
  }

  sg_map_2 = {
    for sg_key, sg_obj in var.security_group_config : sg_key => sg_obj if contains(keys(var.vpc_config), sg_obj.vpc_id)
  }

  sg_map_3 = {
    for sg_key, sg_obj in var.security_group_config : sg_key => {
      "desc" = sg_obj.description
      "ingress_ref" = sg_obj.ingress_ref
      "egress_ref" = sg_obj.egress_ref
      "vpc_id" = sg_obj.vpc_id
    } if contains(keys(var.vpc_config), sg_obj.vpc_id)
  }

  sg_map_4 = {
    for sg_key, sg_obj in var.security_group_config : sg_key => {
      for k, v in sg_obj : 
        k => v if !contains(["ingress","egress","tags"],k)
    } if contains(keys(var.vpc_config), sg_obj.vpc_id)
  }

}
 */


/* 
[for sg_key, sg_obj in var.security_groups : sg_obj.ingress]
*/

# [for sg_key, sg_obj in var.security_groups : sg_obj.ingress]
# flatten([for sg_key, sg_obj in var.security_groups : sg_obj.ingress_ref == null ? sg_obj.ingress : var.shared_security_group_rules[sg_obj.ingress_ref].ingress])
/* 
locals {
  ingress_rules_1 = {
    for enriched_rule in distinct(flatten([for sg_key, sg_obj in var.security_groups : 
      [for rule_idx, rule in sg_obj.ingress : 
        merge(rule, {
          sg_key    ="${sg_key}"
          rule_hash = md5(jsonencode(merge(rule, {sg_key = "${sg_key}"})))
        })
      ]
    ])) : enriched_rule.rule_hash => enriched_rule
  }
} */

/* locals {
  ingress_rules_2 = {
    for enriched_rule in distinct(flatten(
      [for sg_key, sg_obj in var.security_groups : sg_obj.ingress_ref == null ?
        [for rule_idx, rule in sg_obj.ingress : 
          merge(rule, {
            sg_key    ="${sg_key}"
            rule_hash = md5(jsonencode(merge(rule, {sg_key = "${sg_key}"})))
          })
        ] :
        [for rule_idx, rule in var.shared_security_group_rules[sg_obj.ingress_ref].ingress : 
          merge(rule, {
            sg_key    ="${sg_key}"
            rule_hash = md5(jsonencode(merge(rule, {sg_key = "${sg_key}"})))
          })
        ]
      ]
    )) : enriched_rule.rule_hash => enriched_rule
  }
} */


/* {for enriched_rule in distinct(flatten(
  [for sg_key, sg_obj in var.security_groups : sg_obj.ingress_ref == null ?
    [for rule_idx, rule in sg_obj.ingress : 
      merge(rule, {
        sg_key    ="${sg_key}"
        rule_hash = md5(jsonencode(merge(rule, {sg_key = "${sg_key}"})))
      })
    ] :
    [for rule_idx, rule in var.shared_security_group_rules[sg_obj.ingress_ref].ingress : 
      merge(rule, {
        sg_key    ="${sg_key}"
        rule_hash = md5(jsonencode(merge(rule, {sg_key = "${sg_key}"})))
      })
    ]
  ])) : enriched_rule.rule_hash => enriched_rule
} */

/*
[for sg_key, sg_obj in var.security_groups : 
  [for rule_idx, rule in sg_obj.ingress : 
    merge(rule, {
      rule_id="${sg_key}-INGRESS-R${rule_idx}"
      sg_key="${sg_key}"
    })
  ]
]

flatten([for sg_key, sg_obj in var.security_groups : 
  [for rule_idx, rule in sg_obj.ingress : 
    merge(rule, {
      rule_id="${sg_key}-INGRESS-R${rule_idx}"
      sg_key="${sg_key}"
    })
  ]
])


{for enriched_rule in flatten([for sg_key, sg_obj in var.security_groups : 
    [for rule_idx, rule in sg_obj.ingress : 
      merge(rule, {
        rule_id="${sg_key}-INGRESS-R${rule_idx}"
        sg_key="${sg_key}"
      })
    ]
  ]) : enriched_rule.rule_id => enriched_rule
}

{for enriched_rule in flatten([for sg_key, sg_obj in var.security_groups : 
    [for rule_idx, rule in sg_obj.ingress : 
      merge(rule, {
        sg_key="${sg_key}"
      })
    ]
  ]) : md5(jsonencode(enriched_rule)) => enriched_rule
}

flatten([for sg_key, sg_obj in var.security_groups : 
  [for rule_idx, rule in sg_obj.ingress : 
    merge(rule, {
      sg_key    ="${sg_key}"
      rule_hash = md5(<WHAT>)
    })
  ]
])

flatten([for sg_key, sg_obj in var.security_groups : 
  [for rule_idx, rule in sg_obj.ingress : 
    merge(rule, {
      sg_key    ="${sg_key}"
      rule_hash = md5(jsonencode(merge(rule, {sg_key = "${sg_key}"})))
    })
  ]
])
 */
 
/* locals {
  ingress_rules = {
    for enriched_rule in distinct(flatten([for sg_key, sg_obj in var.security_groups : 
      [for rule_idx, rule in sg_obj.ingress : 
        merge(rule, {
          sg_key    ="${sg_key}"
          rule_hash = md5(jsonencode(merge(rule, {sg_key = "${sg_key}"})))
        })
      ]
    ])) : enriched_rule.rule_hash => enriched_rule
  }
}
 */


/* 
# itterate through each vpc_key & vpc_object >> itterate through each vpc_object's subnet map
# for each subnet, construct a new map, with a new semantic compound key (vpc_key + subnet_key)
# merge the original subnet object with 2 additional keys & values for enrichment (vpc_key + subnet_uid)
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
*/


/* 
# itterate through vpc's, returning a list of vpc objects. itterate the vpc objects (SUBNETS), return those as a list
# actually this returns a list, of a list of objects, as per the original structure - which could be flattened - with 'flatten()'
[for vpc_key, vpc_obj in var.vpc_config_2 : [for subnet_key, subnet_obj in vpc_obj.subnets : subnet_obj]]
flatten([for vpc_key, vpc_obj in var.vpc_config_2 : [for subnet_key, subnet_obj in vpc_obj.subnets : subnet_obj]])

# as above but return a MAP of subnet key and subnet objects
# changing the inner loop to a map means we now get a list of a map of objects as per the original structure
[for vpc_key, vpc_obj in var.vpc_config_2 : {for subnet_key, subnet_obj in vpc_obj.subnets : subnet_key => subnet_obj}]
# use merge and spread to flatten this
merge([for vpc_key, vpc_obj in var.vpc_config_2 : {for subnet_key, subnet_obj in vpc_obj.subnets : subnet_key => subnet_obj}]...)

# modify the map keys to be compound keys, 
[for vpc_key, vpc_obj in var.vpc_config_2 : {for subnet_key, subnet_obj in vpc_obj.subnets : "${vpc_key}-${subnet_key}" => subnet_obj}]

# add 'enrichment data' (extra keys) into the object itself, 
[for vpc_key, vpc_obj in var.vpc_config_2 : {for subnet_key, subnet_obj in vpc_obj.subnets : "${vpc_key}-${subnet_key}" => merge(subnet_obj,{vid="${vpc_key}",sid="${vpc_key}-${subnet_key}"}) } ]

# merge it down to a flat map
merge([for vpc_key, vpc_obj in var.vpc_config_2 : {for subnet_key, subnet_obj in vpc_obj.subnets : "${vpc_key}-${subnet_key}" => merge(subnet_obj,{vid="${vpc_key}",sid="${vpc_key}-${subnet_key}"}) } ]...)

# Make it pretty
merge(
    [for vpc_key, vpc_obj in var.vpc_config_2 :
     {for subnet_key, subnet_obj in vpc_obj.subnets :
      "${vpc_key}-${subnet_key}" => 
        merge(
            subnet_obj,
            {vid="${vpc_key}",sid="${vpc_key}-${subnet_key}"}
        ) 
     } 
]...)


 */



/* 
while im doing that. 

something you said earlier i want to ask you about 

"1. Preserve Hierarchical Structure — But Flatten for Consumption
Your vpc_config structure is solid for defining infrastructure. Keep it. But for referencing subnets across modules, create a flattened map with deterministic keys:

This gives you a clean lookup table for subnet references across route tables, EC2 instances, NAT gateways, etc."

What you said here got me thinking about lookups

would i be able to 'lookup' one or more subnet key based on some attribtue data (or combination of attribute data) in the subnet objects?

do you know what im getting at 
 */

 












/* locals {
  nat_gw_route_plan_old = {
    for route_table_key, route_table_object in local.route_table_map : 
    "${route_table_key}__0/0" => {
      "rt_key"  = route_table_key
      "target_key" = local.nat_gw_by_vpc[route_table_object.vpc_key][0]
      "destination_prefix" = "0.0.0.0/0"
    } if route_table_object.inject_nat 
  }
} */




# create a map of public route tables, to drive public route table creation
# -------------------------------------------------------------------------
# using the igw_list above:
# for each igw object, construct a map, keyed with the enriched vpc_key
# IF CREATE AND ATTACH FLAGS ARE BOTH SET
/* locals {
  public_rt_map = {
    for igw_key, igw_obj in local.igw_list :
    "${igw_obj.vpc_key}" => igw_obj if igw_obj.attach && igw_obj.create
  }
}

locals {
  public_subnet_map = {
    for subnet_key, subnet in local.subnet_map :
    subnet_key => subnet if subnet.is_public
  }
}
 */


/* locals {
  private_subnets_with_rt = {
    for vpc_key, vpc in var.vpc_config :
    vpc_key => {
      for subnet_key, subnet in vpc.subnets :
      subnet_key => subnet
      if !subnet.is_public && subnet.has_route_table
    }
  }
} */

/* locals {
  private_subnets_with_rt = {
    for subnet_key, subnet in local.subnet_map :
      subnet_key => subnet if subnet.has_route_table && !subnet.is_public
  }
}

locals {
  public_subnets_with_rt = {
    for subnet_key, subnet in local.subnet_map :
      subnet_key => subnet if subnet.has_route_table && subnet.is_public
  }
}


 */
/* locals {
  igw_route_plan = {
    for route_table_key, route_table_object in local.route_table_map : 
    "${route_table_key}__IGW" => {
      "rt_key"  = route_table_key
      "az"  = route_table_object.az
      "igw" = [for k, v in local.igw_attach_map : k if v.vpc_key == route_table_object.vpc_key][0]
    } if route_table_object.inject_igw
  }
} */



/* locals {
  matching_nat_gw_keys = {
    for route_table_key, route_table_object in local.route_table_map :
    route_table_key => [
      for nat_gw_key, nat_gw_obj in local.nat_gw_map :
      nat_gw_key if nat_gw_obj.vpc_key == route_table_object.vpc_key
    ]
  }
}
 */




/* #VPC GRP
[for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key]
distinct ([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key])
{for vpc_grp_key in distinct ([for nat_gw_key_1, nat_gw_obj_1 in local.nat_gw_map : nat_gw_obj_1.vpc_key]) : vpc_grp_key => "AZ_LIST_HERE!"}

{for vpc_grp_key in distinct ([for k1, o1 in local.nat_gw_map : o1.vpc_key]) : vpc_grp_key => [for k2, o2 in local.nat_gw_map : k2 if o2.vpc_key == vpc_grp_key]}
/*
{for vpc_grp_key in distinct ([for nat_gw_key_1, nat_gw_obj_1 in local.nat_gw_map : nat_gw_obj_1.vpc_key]) : vpc_grp_key => "AZ_LIST_HERE!"}
#AZ GRP
[for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.az]
distinct([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.az])
{for az_grp_key in distinct([for nat_gw_key_2, nat_gw_obj_2 in local.nat_gw_map : nat_gw_obj_2.az]) : az_grp_key => "NAT_GW_LIST HERE"}

{for vpc_grp_key in distinct ([for k1, o1 in local.nat_gw_map : o1.vpc_key]) : 
  vpc_grp_key => {for az_grp_key in distinct([for k2, o2 in local.nat_gw_map : o2.az if o2.vpc_key == vpc_grp_key]) : 
    az_grp_key => [for k3, o3 in local.nat_gw_map : k3 if o3.vpc_key == vpc_grp_key && o3.az == az_grp_key] } }

{for vpc_grp_key in distinct ([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key]) : vpc_grp_key => {for az_grp_key in distinct([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.az]) : az_grp_key => "test"}}

{for az_grp_key in distinct([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.az]) : az_grp_key => "test"}

{for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.az => nat_gw_key if nat_gw_obj.vpc_key == "vpc-lab-dev-100" }

{for vpc_grp_key in distinct ([for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.vpc_key]) : vpc_grp_key => {for nat_gw_key, nat_gw_obj in local.nat_gw_map : nat_gw_obj.az => nat_gw_key if nat_gw_obj.vpc_key == vpc_grp_key }}

[for k3, o3 in local.nat_gw_map : k3 if o3.vpc_key == "vpc-lab-dev-000" && o3.az == "us-east-1a"]
[for k, o in local.nat_gw_map : k if o.vpc_key == "vpc-lab-dev-100" && o.az == "us-east-1a"]

 */
