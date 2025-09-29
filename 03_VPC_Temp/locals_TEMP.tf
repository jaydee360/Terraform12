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
