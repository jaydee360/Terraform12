# itterate through each vpc_key & vpc_object >> itterate through each vpc_object's subnet map
# for each subnet, construct a new map, with a new semantic compound key (vpc_key + subnet_key)
# merge the original subnet object with 2 additional keys & values for enrichment (vpc_key + subnet_uid)
locals {
  subnet_map = merge(
    [for vpc_key, vpc_obj in var.vpc_config :
      { for subnet_key, subnet_obj in vpc_obj.subnets :
        "${vpc_key}-${subnet_key}" => merge(subnet_obj, { vpc_key = "${vpc_key}", subnet_key = "${subnet_key}" })
      }
  ]...)
}



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