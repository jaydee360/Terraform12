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



