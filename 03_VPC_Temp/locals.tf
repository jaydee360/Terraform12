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
