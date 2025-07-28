locals {
  # Load all of the data from json
  all_json_data = jsondecode(file("config_data.json"))

  # Load the vm data directly
  vm_data = jsondecode(file("config_data.json")).VirtualMachines

  # Load the Virtual Network data directly
  vnet_data = jsondecode(file("config_vnetdata.json")).VirtualNetworks

  # Load the first map indirectly
  rg_data = jsondecode(file("config_data.json")).ResourceGroups
}

/* # Output the data fom List1 in the config_data variable, which is defined in the terraform.tfvars.json file
output "JDTEST" {
  value = var.config_data.List1
}
 */
# ---------------------------------------

locals{
  # List of Tuples
  list_of_tuples = [
    for key, object in local.vnet_data : [object.Name, object.AddressSpace]
  ]
}

/* Original (map of lists)
{ for key, value in local.list_of_tuples : key => value}

# New (map of maps)
{ for key, value in local.list_of_tuples : key => { 
        for value-key, value-value in value : value-key => value-value
      } 
}
*/

# ----------------------------------------------------------------------------
# various examples of using for loops to parse data in the comment block below
# ----------------------------------------------------------------------------

/* 
# EXAMPLE of flattening a list of lists

locals {
  all_subnet_names = flatten([
    for vnet_key, vnet_object in local.vnet_data :
    contains(keys(vnet_object), "Subnets") ?
      [for subnet in vnet_object.Subnets : "${subnet.Name}"] : []
  ])
}

*/


/* 
# EXAMPLE of converting a list of lists to a map of maps

tomap(
  {for list-key, list-item in local.list_of_tuples : 
  list-key => 
    {for sub-list-key, sub-list-item in list-item : 
    sub-list-key => 
      sub-list-item
    }
  }
)

*/


/* 
# EXAMPLE of converting a list of lists to a map of maps with string keys

{
  for list-key, list-item in local.list_of_tuples :
  tostring(list-key) => {
    for sub-list-key, sub-list-item in list-item :
    tostring(sub-list-key) => sub-list-item
  }
}

*/

/*
# EXAMPLE of filtering out a specific key from a map of objects

{
  for vnet-key, vnet-data in local.vnet_data :
  vnet-key => 
    {for key, val in vnet-data : key => val if key != "Subnets"}
}

*/

/*
#EXAMPLE of filtering and entire object from a map of objects, based on a contained object key

{
  for vnet-key, vnet-data in local.vnet_data :
  vnet-key => 
    {for key, val in vnet-data : key => val} if contains(keys(vnet-data),"Subnets")
}


/* 
#EXAMPLE both filtering out a specific key, AND filtering and entire object from a map of objects

{
  for vnet-key, vnet-data in local.vnet_data :
  vnet-key => 
    {for key, val in vnet-data : key => val if key != "Subnets"} if contains(keys(vnet-data),"Subnets")
}
*/

/* 
# EXAMPLE filter in / out sub-list items based on an exact match from the list 
# NOTE this will return empty list item where match is FALSE

[
  for list-item in local.list_of_tuples : 
  [for sub-list-item in list-item : sub-list-item if contains(list-item,"VNET-HUB-EUS-01")]
]

# EXAMPLE same as above, but with a count condition to include the list item only if it contains non-zero items in the sub-list

[
  for list-item in local.list_of_tuples : 
  ([for sub-list-item in list-item : sub-list-item if contains(list-item,"VNET-HUB-EUS-01")])
  if length([for sub-list-item in list-item : sub-list-item if contains(list-item,"VNET-HUB-EUS-01")]) > 0
]

*/

/* 
# EXAMPLE transform a list/sublist into a map of same keys and values

{
  for list-item in local.list_of_tuples : list-item[0] => 
  {
    name=list-item[0], 
    cidr=list-item[1]
  }
}

*/


/* 
# EXAMPLE as above but with 'IF' condition AFTER the value, (acting as a filter)

{
  for list-item in local.list_of_tuples : list-item[0] => 
  {
    name=list-item[0], 
    cidr=list-item[1]
  } 
  if !startswith((list-item[0]),"VNET-HUB")
}

*/

/* 
# EXAMPLE same transform a list/sublist into a map of same keys and values
# but using condition BEFORE the VALUE (acting as a transformer, with ? {TRUE} : {FALSE} value substitution)

{
  for list-item in local.list_of_tuples : list-item[0] => !startswith((list-item[0]),"VNET-HUB") ? 
  {
    name=list-item[0], 
    cidr=list-item[1]
  } : 
  {
    name="SUBSTITUTE-NAME", 
    cidr="SUBSTITUTE-CIDR"
  }
}
*/