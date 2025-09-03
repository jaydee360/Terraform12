# progressive itteration and transformation to build a map for igw creation

# create a list of IGW object from the master vpc data (vpc_config)
# ----------------------------------------------------------
# itterate through each vpc_key & vpc_object
# using the the vpc_object's IGW object, (if it exists), create a new list
# to create each list item, merge the original IGW object with parent vpc_key for enrichment (used to build the other maps below)
locals {
  igw_list = [
    for vpc_key, vpc_obj in var.vpc_config :
    merge(vpc_obj.igw, { "vpc_key" = "${vpc_key}" }) if vpc_obj.igw != null
  ]
}

# create a map of igw's, to drive  igw resource creation
# ------------------------------------------------------
# using the igw_list above:
# for each igw object, construct a map, keyed with the enriched vpc_key,
# IF CREATE FLAG IS SET
locals {
  igw_create_map = {
    for igw_key, igw_obj in local.igw_list :
    "${igw_obj.vpc_key}" => igw_obj if igw_obj.create
  }
}

locals {
  test_igw_create_map = {
    for vpc_key, vpc_obj in var.vpc_config :
    vpc_key => vpc_obj.igw if vpc_obj.igw != null
  }
}

# create a map of igw's, to drive igw attachment creation
# -------------------------------------------------------
# using the igw_list above:
# for each igw object, construct a map, keyed with the enriched vpc_key
# IF CREATE AND ATTACH FLAGS ARE BOTH SET
locals {
  igw_attach_map = {
    for igw_key, igw_obj in local.igw_list :
    "${igw_obj.vpc_key}" => igw_obj if igw_obj.attach && igw_obj.create
  }
}

# create a map of public route tables, to drive public route table creation
# -------------------------------------------------------------------------
# using the igw_list above:
# for each igw object, construct a map, keyed with the enriched vpc_key
# IF CREATE AND ATTACH FLAGS ARE BOTH SET
locals {
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

locals {
  nat_gw_map = {
    for subnet_key, subnet in local.subnet_map :
    subnet_key => subnet if subnet.has_nat_gw
  }
}

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

locals {
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
    )
  } 
}

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

locals {
  igw_route_plan = {
    for route_table_key, route_table_object in local.route_table_map : 
    "${route_table_key}__0/0" => {
      "rt_key"  = route_table_key
      "target_key" = route_table_object.vpc_key
      "destination_prefix" = "0.0.0.0/0"
    } if route_table_object.inject_igw
  }
}

locals {
  matching_nat_gw_keys = {
    for route_table_key, route_table_object in local.route_table_map :
    route_table_key => [
      for nat_gw_key, nat_gw_obj in local.nat_gw_map :
      nat_gw_key if nat_gw_obj.vpc_key == route_table_object.vpc_key
    ]
  }

  nat_gw_route_plan = {
    for route_table_key, route_table_object in local.route_table_map : 
    "${route_table_key}__0/0" => {
      "rt_key"  = route_table_key
      "target_key" = local.nat_gw_by_vpc[route_table_object.vpc_key][0]
      "destination_prefix" = "0.0.0.0/0"
    } if route_table_object.inject_nat 
  }
}

locals {
  nat_gw_by_vpc_az = {
    for vpc_grp_key in distinct ([for k1, o1 in local.nat_gw_map : o1.vpc_key]) : 
      vpc_grp_key => {for az_grp_key in distinct([for k2, o2 in local.nat_gw_map : o2.az if o2.vpc_key == vpc_grp_key]) : 
        az_grp_key => [for k3, o3 in local.nat_gw_map : k3 if o3.vpc_key == vpc_grp_key && o3.az == az_grp_key] 
      } 
  }

  nat_gw_by_vpc = {
    for vpc_grp_key in distinct ([for k1, o1 in local.nat_gw_map : o1.vpc_key]) : 
      vpc_grp_key => [for k2, o2 in local.nat_gw_map : k2 if o2.vpc_key == vpc_grp_key]
  }
}

locals {
  valid_route_table_keys = keys(local.route_table_map)

  subnet_route_table_associations = [
    for subnet_key, subnet in local.subnet_map : 
    subnet_key if subnet.has_route_table && contains(local.valid_route_table_keys, subnet_key)
  ]
}

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
