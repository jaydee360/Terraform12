# Example 1
# ---------
variable "teams" {
    type = map(object({
        members =  list(string)
    }))
    default = {
      "engineering" = {
        "members" = ["alice", "bob"]
      }
      "design" = {
        "members" = ["carol"]
      }
    }
}

# Solution
# --------
locals {
    solution_1 = merge([for k, v in var.teams : {for kk, vv in v.members : "${k}-${vv}" => k}]...)
}


# Example 2
# ---------
variable "vpcs" {
    type = map(object({
      subnets = map(object({
        cidr = string
      })) 
    }))
    default = {
        "vpc-a" = {
            subnets = {
                "subnet-a1" = {cidr = "10.0.1.0/24"}
                "subnet-a2" = {cidr = "10.0.2.0/24"}
            }
        }
        "vpc-b" = {
            subnets = {
                "subnet-b1" = { cidr = "10.1.1.0/24" }
            }
        }
    }
}

locals {
    solution_2 = merge([for k, v in var.vpcs : {for kk, vv in v.subnets : "${k}-${kk}" => vv.cidr}]...)
}

# Example 3
# ---------
variable "subnets" {
    type = map(object({
        is_public = bool
        route_table_key = optional(string) 
    }))
    default = {
        subnet-a1 = {
            is_public = true
        }
        subnet-a2 = {
            is_public = false
        }
        subnet-a3 = {
            is_public = true
            route_table_key = "custom-rt-a3"
        }
    }
}

# Solution 3
# ----------
# Solution_3 works, but failure_3a / failure_3b do not work as expected
locals {
    solution_3 = {for sub_key, sub_data in var.subnets : sub_key => sub_data.route_table_key != null ? sub_data.route_table_key : (sub_data.is_public ? "public_rt" : "private_rt")}
    failure_3a = {for sub_key, sub_data in var.subnets : sub_key => lookup(sub_data, "route_table_key", "FALLBACK")}
    failure_3b = {for sub_key, sub_data in var.subnets : sub_key => contains(keys(sub_data), "route_table_key") ? sub_data.route_table_key : "FALLBACK"}
}
# The original intention was to use LOOKUP or CONTAINS with a fallback value in case 'route_table_key' does not exist in the object
# This does not work with a data structure like the one above, where 'route_table_key' is OPTIONAL, and is ommited from some objects
# Wherr the OPTIONAL key isn’t “created” in the input variable data, it’s always materialized in the resulting object with a NULL value.

# Terraform ensures OPTIONAL keys are always present in objects. Where OPTIONAL keys omitted from object, terraform assigns the key with a value of NULL
# This is part of Terraform's type coercion and schema enforcement. Optional attributes default to NULL to maintain structural consistency. 
# This allows better safety. Expressions can reference the attribute without checking for its existence.
# Sadly, it also means fallback logic (like in LOOKUP()) must handle 'null' rather than missing keys. 

# Example 3a
# ----------
# use a loosely typed declaration where the key can truly be absent
variable "subnets_a" {
    type = map(any)
    default = {
        subnet-a1 = {
            is_public = true
        }
        subnet-a2 = {
            is_public = false
        }
        subnet-a3 = {
            is_public = true
            route_table_key = "custom-rt-a3"
        }
    }
}
# The solutions below how the fallback behavour in LOOKUP and CONTAINS works as expected where the keys are absent from the input
# Notice also how attempting to evaluate NULL values will fail, if the route_table_key no longer exists (failure_3aa)
locals {
    failure_3aa = {for sub_key, sub_data in var.subnets_a : sub_key => sub_data.route_table_key != null ? sub_data.route_table_key : (sub_data.is_public ? "public_rt" : "private_rt")}
    solution_3aa = {for sub_key, sub_data in var.subnets_a : sub_key => lookup(sub_data, "route_table_key", (sub_data.is_public ? "public_rt" : "private_rt"))}
    solution_3bb = {for sub_key, sub_data in var.subnets_a : sub_key => contains(keys(sub_data), "route_table_key") ? sub_data.route_table_key : (sub_data.is_public ? "public_rt" : "private_rt")}
}

# Example 4
# ---------
variable "routes" {
    type = list(object({
        cidr = string
        target_type = string
        target_key = string 
    }))
    default = [
        { cidr = "0.0.0.0/0", target_type = "igw", target_key = "vpc-a" },
        { cidr = "0.0.0.0/0", target_type = "nat", target_key = "nat-a" },
        { cidr = "10.100.0.0/16", target_type = "tgw", target_key = "tgw-a" }
    ]
}

locals {
    route_targets = {
        igw = { "vpc-a" = "igw-123" }
        nat = { "nat-a" = "nat-456" }
        tgw = { "tgw-a" = "tgw-789" }
    }
}

# Solution 4
# ----------
# Development Steps
# 1. make compound key with simple value
#    {for route in var.routes : "${route.cidr}-${route.target_type}" => route.target_type}
# 2. test nested lookups
#    lookup(local.route_targets, "igw")
#    lookup(lookup(local.route_targets, "igw"),"vpc-a")

locals {
    solution_4  = {for route in var.routes : "${route.cidr}-${route.target_type}" => route.target_type}
    solution_4a = {for route in var.routes : "${route.cidr}-${route.target_type}" => lookup(lookup(local.route_targets,route.target_type),route.target_key)}
    solution_4b = {for route in var.routes : "${route.cidr}-${route.target_type}" => local.route_targets[route.target_type][route.target_key]}
}

# Exercise 5: Conditional Resource Targeting with Semantic Keys
# -------------------------------------------------------------
variable "subnets_5" {
  type = map(object({
    vpc_key          = string
    is_public        = bool
    route_table_key = optional(string)
  }))
  default = {
    "subnet-a1" = {
      vpc_key          = "vpc-a"
      is_public        = true
    }
    "subnet-a2" = {
      vpc_key          = "vpc-a"
      is_public        = false
      route_table_key  = "custom-rt-a2"
    }
    "subnet-b1" = {
      vpc_key          = "vpc-b"
      is_public        = true
    }
  }
}

# solution
locals {
    solution_5 = {for sub_key, sub_map in var.subnets_5 : sub_key => sub_map.route_table_key != null ? sub_map.route_table_key : (sub_map.is_public ? "${sub_map.vpc_key}-public" : "${sub_map.vpc_key}-private")}
}

# Exercise 6: Reverse Mapping of Resource Associations
# ----------------------------------------------------

locals {
  subnet_to_rt = {
    "subnet-a1" = "rt-1"
    "subnet-a2" = "rt-2"
    "subnet-a3" = "rt-1"
  }
}

# FIRST STEP
# My first instinct was to start with the DISTINCT rt values above, as these would the new map keys for the reverse mapping objective
# I made this ti get the distinct values from the map
# > distinct([for rt in local.subnet_to_rt : v])

# i recalled the transformation which reorganised a list of Resource Groups by their provider_alias
# this transformation used a distinct function to deduplicate a list of provider alias from each resource group object
# looking back, this transformaton is logically similar to a reverse mapping

# > {
# >   for UNIQUE_PROVIDER_ALIAS in distinct([for RG_OBJECT in var.resource_groups : RG_OBJECT.provider_alias]) : UNIQUE_PROVIDER_ALIAS => {
# >     for RG_KEY, RG_OBJ in var.resource_groups : RG_KEY => RG_OBJ if UNIQUE_PROVIDER_ALIAS == RG_OBJ.provider_alias
# >   }
# > }

# FIRST STEP NOTE:
# Rather than collating the rt's using a for loop, I learned afterwards its more elegant to use values() funtion which returns a list of values from the 'subnet_to_rt' map:
# > distinct(values(local.subnet_to_rt))

# While i understood that these distinct values would drive the first loop, i failed to understand how to create the expression required to build a new map from these distinct value

# SECOND STEPS
# Attempting to get my head around the problem I tried to see what would happen if i just did a straight swap of the keys and values in a simple map comprehention
# > {for key, value in local.subnet_to_rt : value => key}
# ERROR: Two different items produced the key "rt-1" in this 'for' expression. If duplicates are expected, use the ellipsis (...) after the value expression to enable grouping by key
# CLUE:  Using the ellipsis (...) after the VALUE in the map epression (KEY => VALUE...) will group values together that have a common key. This is EXACTLY what we want
# > {for key, value in local.subnet_to_rt : value => key...}
# while the above loop does actually give us a solution, it was an accidental discovery and not the solution i had in mind

# THIRD STEP
# i tried to experiment using a literal "rt-1" to build a single map, keyed to the same literal, with value filter also using the same literal...  
# - but this failed with 'Duplicate object key'
# > {for rt in local.subnet_to_rt : "rt-1" => [for key, value in local.subnet_to_rt : key if value == "rt-1"]}
# i didnt understand the failure at first, but i now undestand that the first loop would end up productung the same literal key "rt-1"  3 times, for 3 itterations which obviously is not allowed in a map
# - Why 3? The first loop has 3 itterations because there are 3 items in the original 'subnet_to_rt' map

# if the intention was to produce a simplified POC loop driven by a literal, the approach below should have been used. Sadly i did not work this out for myself
# > {for literal_rt in ["rt-1"] : literal_rt => [for snet, rt in local.subnet_to_rt : snet if rt == literal_rt]}
# This can be expanded to include more literals in the list, as a substitute for the DISTINCT
# > {for literal_rt in ["rt-1", "rt-2"] : literal_rt => [for snet, rt in local.subnet_to_rt : snet if rt == literal_rt]}

# FINAL SOLUTION
# The last step is to replace the literal list with the deduplicated list of map values using the distinct() function from earlier
# The iteration variables are CAPITALISED for clarity
# > {for DISTINCT_RT in distinct(values(local.subnet_to_rt)) : DISTINCT_RT => [for SUBNET, RT in local.subnet_to_rt : SUBNET if RT == DISTINCT_RT]}


# Exercise 7: Multi-Stage Lookup with Fallback

 locals {
  route_targets_7 = {
    igw = { "vpc-a" = "igw-123" }
    nat = { "nat-a" = "nat-456" }
  }
}


variable "routes_7" {
  type = list(object({
    cidr        = string
    target_type = string
    target_key  = string
  }))
  default = [
    {
      cidr        = "10.0.0.0/16"
      target_type = "igw"
      target_key  = "vpc-a"
    },
    {
      cidr        = "10.0.1.0/24"
      target_type = "tgw"
      target_key  = "tgw-a"
    },
    {
      cidr        = "10.0.2.0/24"
      target_type = "nat"
      target_key  = "nat-a"
    }
  ]
}

# STEP ONE
# create a simple loop to test the compund key creation. This uses a literal as a placeholder value
# > {for v in var.routes_7 : "${v.cidr}-${v.target_type}" => "hello"}

# STEP TWO
# The callenge 'hint' said "Use nested lookup() with fallback logic"
# create a PoC for the route target lookup using nested lookups
# To use this approach worked well for valid lookups
# > lookup(lookup(local.route_targets_7,"igw"),"vpc-a")

# however, in case of a failed lookup, any fallback value in the lookup function will cause the nested lookup to break
# > lookup(lookup(local.route_targets_7,"tgw","InnerFallback"),"tgw-a","OuterFallback")

# if the inner lookup fails to match the specified map attribute, the fallback returns a string, which breaks the outer lookup.
# The lookup() function requres a map as its input, not a string
# Consequently its not practical to use nested lookups that provide a controlled fallback

# STEP THREE
# considering that both lookups (inner and outer) form a single compound lookup, my instinct was to use the try() function to contain failure, and provide fallback
# Also for some reason (which i dont fully understand), i abandoned nested lookups and switched to the [index] method for direct lookup of values

# First, i created a PoC for the route target lookups using both valid and invalid lookup data

# valid lookup
# > try(local.route_targets_7["igw"]["vpc-a"],"default-tgw")
# invaild lookup
# > try(local.route_targets_7["tgw"]["tgw-a"],"default-tgw")

# after testing the PoC, i implemented the same lookup logic in a for loop. This creates a value in the key expression for each itteraction,
# try() provides the fallback if the indexed lookup fails for any reason

# SOLUTION 7a
# -----------
# > {for ROUTE in var.routes_7 : "${ROUTE.cidr}-${ROUTE.target_type}" => try(local.route_targets_7[ROUTE.target_type][ROUTE.target_key],"default-tgw")}

# Further to SOLUTION 7a, i now realise that the nested lookup approach becomes feasable if the lookups are encapsulated in a try() function to handle any failure
# this would allow me to provide a fallback value for any failure

# I created the same PoC to test using nested lookups 

# vaild lookup
# > try(lookup(lookup(local.route_targets_7,"igw"),"vpc-a"),"default-tgw")

# invaild lookup
# > try(lookup(lookup(local.route_targets_7,"tgw"),"tgw-a"),"default-tgw")

# using this approach proves that nested lookups are made'safe' with try()

# SOLUTION 7b
# -----------
# > {for ROUTE in var.routes_7 : "${ROUTE.cidr}-${ROUTE.target_type}" => try(lookup(lookup(local.route_targets_7, ROUTE.target_type), ROUTE.target_key),"default-tgw")}

