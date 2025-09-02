/* 
Exercise 12: Environment-Specific Resource Aggregation
Scenario: 
You manage a fleet of resources tagged by environment. You want to group them by environment, but only include environments with more than two resources to reduce dashboard noise.
Goal: 
Produce a map of environment → list of resource names, excluding environments with ≤2 entries.
Variable Declaration:
*/
variable "resources" {
  default = [
    { name = "db1", env = "prod" },
    { name = "db2", env = "prod" },
    { name = "db3", env = "prod" },
    { name = "web1", env = "dev" },
    { name = "web2", env = "dev" },
    { name = "app1", env = "test" },
    { name = "app2", env = "test" },
    { name = "app3", env = "test" },
    { name = "app4", env = "test" }
  ]
}

/*
Example Output:
{
  "prod" = ["db1", "db2", "db3"]
}
*/

/* 
# from the list of maps, loop, isolate and extract the envs in each map
[for element in var.resources : element.env]

# dedupe them for uniqueness
distinct([for element in var.resources : element.env])

# loop through the unique list of envs. using each env as a key, create a list of resrouces per env
{for env_group in distinct([for element in var.resources : element.env]) : env_group => [for resource in var.resources : resource.name if resource.env == env_group]}

# post-filtering: loop through the finished map. rebuild the map to include list with > 2 items
{for key, list in {for env_group in distinct([for element in var.resources : element.env]) : env_group => [for resource in var.resources : resource.name if resource.env == env_group]} : key => list if length(list) > 2}
*/

variable "routes_by_subnet_v1" {
  default = {
    "subnet-a" = [
      { cidr = "10.0.0.0/16", target = "igw" },
      { cidr = "0.0.0.0/0", target = "nat" }
    ],
    "subnet-b" = [
      { cidr = "192.168.0.0/16", target = "vpn" }
    ]
  }
}

variable "routes_by_subnet_v2" {
  default = {
    # ✅ Normal case: multiple valid routes
    "subnet-a" = [
      { cidr = "10.0.0.0/16", target = "igw" },
      { cidr = "0.0.0.0/0", target = "nat" }
    ],
    # ⚠️ Empty route list (should contribute nothing)
    "subnet-b" = [],
    # ⚠️ Route with missing fields (test null-safe access or validation)
    "subnet-c" = [
      { cidr = "172.16.0.0/12" }  # missing target
    ],
    # ✅ Normal case: single route
    "subnet-d" = [
      { cidr = "192.168.0.0/16", target = "vpn" }
    ],
    # ⚠️ Duplicate route (test deduping or intentional repetition)
    "subnet-e" = [
      { cidr = "10.0.0.0/16", target = "igw" },
      { cidr = "10.0.0.0/16", target = "igw" }
    ]
  }
}

variable "routes_by_subnet" {
    type = map(list(object({
      cidr = string
      target = optional(string)
    })))
    default = {
    # ✅ Normal case: multiple valid routes
    "subnet-a" = [
      { cidr = "10.0.0.0/16", target = "igw" },
      { cidr = "0.0.0.0/0", target = "nat" }
    ],
    # ⚠️ Empty route list (should contribute nothing)
    "subnet-b" = [],
    # ⚠️ Route with missing fields (test null-safe access or validation)
    "subnet-c" = [
      { cidr = "172.16.0.0/12" }  # missing target
    ],
    # ✅ Normal case: single route
    "subnet-d" = [
      { cidr = "192.168.0.0/16", target = "vpn" }
    ],
    # ⚠️ Duplicate route (test deduping or intentional repetition)
    "subnet-e" = [
      { cidr = "10.0.0.0/16", target = "igw" },
      { cidr = "10.0.0.0/16", target = "igw" }
    ]
  }
}

/* # loop the top level subnet map and route objects
[for subnet_key, route_list in var.routes_by_subnet : route_list]

# loop the top level subnet map and route objects loop again the individual route maps inside each route object
[for subnet_key, route_list in var.routes_by_subnet : [for route in route_list : route]]

# for each itteration through subnet map, route object, and route, reconstruct a new route object, return as a list 
[for subnet_key, route_list in var.routes_by_subnet : [for route in route_list : {
    subnet = subnet_key,
    cidr = route.cidr
    target = route.target
}]]

# flatten the list
flatten([for subnet_key, route_list in var.routes_by_subnet : [for route in route_list : {
    subnet = subnet_key,
    cidr = route.cidr
    target = route.target
}]])

# dedupe the flattened list
distinct(flatten([for subnet_key, route_list in var.routes_by_subnet : [for route in route_list : {
    subnet = subnet_key,
    cidr = route.cidr
    target = route.target
}]]))

 */

 variable "instances" {
  default = [
    { id = "i-abc", region = "us-east-1", tier = "frontend" },
    { id = "i-def", region = "us-east-1", tier = "backend" },
    { id = "i-ghi", region = "us-west-2", tier = "frontend" },
    { id = "i-jkl", region = "us-west-2", tier = "backend" },
    { id = "i-mno", region = "us-west-1", tier = "frontend" },
    { id = "i-pqr", region = "us-west-1", tier = "backend" },
    { id = "i-stu", region = "us-west-2", tier = "frontend" },
    { id = "i-vwx", region = "us-west-2", tier = "backend" },
  ]
}
/* 
# iterate the list, produce the compound keys as an example
[for element in var.instances : "${element.region}:${element.tier}"]

# dedupe the compound keys
# the original data set didnt have instances with duplicate combinations of compound keys, so i added more
distinct([for element in var.instances : "${element.region}:${element.tier}"])

#------->
# the problem with compound keys is that they are computed
# they need to be used in various ways (dedupe, grouping, and filtering) at different stages of the map comprehension and transformation
# there needs to be a way to store and reference the compound key for each operation
# My solution is to enrich each object with its corresponding compound key
# this is achieved by iterating the list and merging each original list element map with a new map containing the computed key (uid)
[for element in var.instances : merge(element,{uid = "${element.region}:${element.tier}"})]

# now i can loop through the 'enriched' objects
[for enriched_element in [for element in var.instances : merge(element,{uid = "${element.region}:${element.tier}"})] : enriched_element.uid]

# then, deduplicate them
distinct([for enriched_element in [for element in var.instances : merge(element,{uid = "${element.region}:${element.tier}"})] : enriched_element.uid])

# then, reference as a grp_key, as a key for a new map 
{for grp_key in distinct([for enriched_element in [for element in var.instances : merge(element,{uid = "${element.region}:${element.tier}"})] : enriched_element.uid]) : grp_key => "test"}

# constructing the map values gets complicated, because the enrichment needs to be performed again, so it can be used to match the inner list values with the outer list keys
{for grp_key in distinct([for enriched_element in [for element in var.instances : merge(element,{uid = "${element.region}:${element.tier}"})] : enriched_element.uid]) : grp_key => [for enr_elmnt in [for elmnt in var.instances : merge(elmnt,{uid = "${elmnt.region}:${elmnt.tier}"})] : enr_elmnt if enr_elmnt.uid == grp_key]}

#------->
 */
# better more readable solution is to create this enriched intermediate data as a local
locals {
    intermediate_map = [
        for element in var.instances : 
        merge(element, {uid = "${element.region}:${element.tier}"})
    ]
}
/* 
# that makes the transfomation much simpler
{for grp_key in distinct([for element in local.intermediate_map : element.uid]) : 
    grp_key => [for elmnt in local.intermediate_map : elmnt if elmnt.uid == grp_key]
} 
 */

