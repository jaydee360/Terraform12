# Theme 1: Subnet Selection for Tiered Deployment
# Select subnets based on tier (e.g. web, app, db) and environment (prod, dev), then group them by AZ.

variable "subnet_meta" {
  type = map(object({
    tier = string
    env  = string
    az   = string
  }))
  default = {
    "subnet-web-a" = { tier = "web", env = "prod", az = "a" }
    "subnet-app-a" = { tier = "app", env = "prod", az = "a" }
    "subnet-db-a"  = { tier = "db",  env = "dev",  az = "a" }
    "subnet-web-b" = { tier = "web", env = "prod", az = "b" }
    "subnet-app-b" = { tier = "app", env = "prod", az = "b" }
    "subnet-db-b"  = { tier = "db",  env = "dev",  az = "b" }
  }
}

variable "target_env" { default = "prod" }
variable "target_tiers" { default = ["web", "app"] }

# Example Output:
/* 
{
  "a" = ["subnet-web-a", "subnet-app-a"]
  "b" = ["subnet-web-b", "subnet-app-b"]
} 
*/

# Step 1
# check filter variables
# > var.target_env
# > [for TIER in var.target_tiers : TIER]

# Step 2
# get unique az's
# > [for k, v in var.subnet_meta : v.az]
# > distinct([for k, v in var.subnet_meta : v.az])

# Step 3
# build reverse map of subnets, grouped by az 
# > {for UNIQUE_AZ in distinct([for k, v in var.subnet_meta : v.az]) : UNIQUE_AZ => 
# >     [for SNET_KEY, SNET_OBJ in var.subnet_meta : SNET_KEY if SNET_OBJ.az == UNIQUE_AZ]
# > }

# Step 4
# build the map filters individually

# reproduce same map basic map
# > {for KEY, OBJ in var.subnet_meta : KEY => OBJ}
# same map, filtered on target_env
# > {for KEY, OBJ in var.subnet_meta : KEY => OBJ if OBJ.env == var.target_env}
# A HINT WAS REQUIRED for the next filter - using contains()
# same map,  filtered where object.tier is a member of the [target_tiers] list - using contains()
# > {for KEY, OBJ in var.subnet_meta : KEY => OBJ if contains(var.target_tiers, OBJ.tier)}
# combine both the above filters using &&
# > {for KEY, OBJ in var.subnet_meta : KEY => OBJ if (OBJ.env == var.target_env && contains(var.target_tiers, OBJ.tier))}
# > {for KEY, OBJ in var.subnet_meta : KEY => OBJ if (OBJ.az == "a" && OBJ.env == var.target_env && contains(var.target_tiers, OBJ.tier))}

# SOLUTION 1 (BEST)
# ----------
# combine them all
# > {for UNIQUE_AZ in distinct([for k, v in var.subnet_meta : v.az]) : UNIQUE_AZ => [for SNET_KEY, SNET_OBJ in var.subnet_meta : SNET_KEY if (SNET_OBJ.az == UNIQUE_AZ && SNET_OBJ.env == var.target_env && contains(var.target_tiers, SNET_OBJ.tier))]}

# ALTERNATE SOLUTIONS
# -------------------
# This are alternate ways of doing value membership - same as contains() - but using nested loops. Its horribly unreadable though:
# ALTERNATE 1
# > { for KEY, OBJ in var.subnet_meta : KEY => OBJ if length([for TIER in var.target_tiers : TIER if TIER == OBJ.tier]) > 0 }
# The inner list comprehension [for tier in var.target_tiers : tier if tier == obj.tier] builds a list of matches.
# If the list has length > 0, it means obj.tier was found in target_tiers.
# ALTERNATE 2
# > flatten([for tier in var.target_tiers : [for key, obj in var.subnet_meta : key if obj.tier == tier && obj.env == var.target_env]])
# Iterates over each tier in target_tiers
# For each tier, filters the subnet map for matching tier and env
# Returns a list of lists, which is then flattened into a single list of subnet keys


# SOLUTION 1a
# -----------
# > {for UNIQUE_AZ in distinct([for k, v in var.subnet_meta : v.az]) : UNIQUE_AZ => 
# >     [for SNET_KEY, SNET_OBJ in var.subnet_meta : SNET_KEY if SNET_OBJ.az == UNIQUE_AZ && length([for TIER in var.target_tiers : TIER if TIER == SNET_OBJ.tier]) > 0]
# > }

# SOLUTION 1b
# -----------
# > {for UNIQUE_AZ in distinct([for k, v in var.subnet_meta : v.az]) : UNIQUE_AZ => 
# >     flatten([for TIER in var.target_tiers : 
# >         [for SNET_KEY, SNET_OBJ in var.subnet_meta : SNET_KEY if SNET_OBJ.az == UNIQUE_AZ && SNET_OBJ.env == var.target_env && SNET_OBJ.tier == TIER]
# >     ])
# > }

# Theme 4: Flattening Nested Module Outputs
# -----------------------------------------
variable "routes" {
  type = list(object({
    cidr        = string
    target_type = string
    target_key  = string
  }))
  default = [
    { cidr = "10.0.1.0/24", target_type = "igw", target_key = "igw-a" },
    { cidr = "10.0.2.0/24", target_type = "tgw", target_key = "tgw-a" },
    { cidr = "10.0.3.0/24", target_type = "none", target_key = "" }
  ]
}

variable "route_targets" {
  type = map(map(string))
  default = {
    igw = { "igw-a" = "igw-123" }
    tgw = { "tgw-a" = "tgw-456" }
  }
}

/* 
Transform a list of route specs into a map of route blocks, skipping invalid or incomplete entries.
example outbput
{
  "10.0.1.0/24-igw" = { cidr = "10.0.1.0/24", target_id = "igw-123" }
  "10.0.2.0/24-tgw" = { cidr = "10.0.2.0/24", target_id = "tgw-456" }
}
*/

# Step 1
# Test transforming the list into a map with compound key. 
# Use a dummy value for simplicity
# > {for ELEMENT in var.routes : "${ELEMENT.cidr}-${ELEMENT.target_type}" => "test"}

# Step 2
# Try to create a method to filter out invalid / incomplete entries

# First, test valid lookup using literals
# > var.route_targets["igw"]["igw-a"]
# > var.route_targets["tgw"]["tgw-a"]

# Then, test invalid lookup using literals
# > var.route_targets["none"][""]

# Finally, test use of safety functions for invalid lookups
# > try(var.route_targets["none"][""])
# > try(var.route_targets["none"][""],"fallback")
# > can(var.route_targets["none"][""])
# > can(var.route_targets["none"][""]) ? "yes" : "no"

# Step 3
# try to use this in a map expression 
# This FAILS, becuase you cannot use a ternary expression to build a map ( key => value )
# > {for ELEMENT in var.routes : can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key]) ? ELEMENT.cidr => "test"} : "no"}

# Instead, try to build a filtered shortlist of routes with complete & valid lookups
# > [for ELEMENT in var.routes : can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key]) ? ELEMENT : null]
# This works but the result contains a null object where the lookup fails. THis is what happens when you use a ternary expression with a 'null' if false

# Step 4
# I didnt think the null object would cause a problem,  so next i try to wrap the inner loop 'shortlist' into an outer loop 
# the purpose of the outer loop is to create a new map from the shortlist 
# this simple prototype map uses a static literal value for simplicity 
# > {for VALID_ELEMENT in [for ELEMENT in var.routes : can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key]) ? ELEMENT : null] : VALID_ELEMENT.cidr => "test"}
# However, this fails because of the null object thats contained in the shortlist

# I tries to handle the null using a ternary expression again. The idea is to produce the map if ELEMENT is not null
# > {for VALID_ELEMENT in [for ELEMENT in var.routes : can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key]) ? ELEMENT : null] : VALID_ELEMENT != null ? VALID_ELEMENT.cidr => "test" : null}
# This FAILS for the same reason as Step 3. Terraform doesnt permit the use of ternary expression when building a map (CONDITION ? key => value : ELSE...)
# you basically cant do this

# I tried to remove the null using compact() 
# > compact([for ELEMENT in var.routes : can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key]) ? ELEMENT : null])
# this doesnt work becuase compact() only works on strings

# After being stuck here for a while, the solution was ultimately to avoid using ternary expression. 
# If the goal is to create a new map only if the lookup is successful (as determined by the result of the can(lookup)), this can be achieved by using the can(lookup) in an 'if' filter
# > {for ELEMENT in var.routes : "${ELEMENT.cidr}-${ELEMENT.target_type}" => ELEMENT if can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key])}
# this is the final step in the construction of the loop logic

# SOLUTION
# --------
# The final solution merely adds logic to create the attributes in the new map object as per the exercise goal
# > {for ELEMENT in var.routes : "${ELEMENT.cidr}-${ELEMENT.target_type}" => {cidr = ELEMENT.cidr, target_id = var.route_targets[ELEMENT.target_type][ELEMENT.target_key]} if can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key])}

# SOLUTION B
# ----------
# having learned my lesson on how (and why) not to use termnaries in list and map creation
# I wanted to revisit my previous approach, using an inner loop for shortlist, and an outer loop for map construction
# First, I re-made the shortlist using the same 'if' filter approach rather than building it using ternary logic. This appraoch avoids creating null objects in the shortlist
# and avoids outer loop processing issues caused by the existence of nulls
# > [for ELEMENT in var.routes : ELEMENT if can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key])]

# Then, I was able to test the inner loop shortlist with an outer loop to build a new simplified map
# > {for VALID_ELEMENT in [for ELEMENT in var.routes : ELEMENT if can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key])] : VALID_ELEMENT.cidr => "test" }

# finally I could refine the map values to meet the original goal
# > {for VALID_ELEMENT in [for ELEMENT in var.routes : ELEMENT if can(var.route_targets[ELEMENT.target_type][ELEMENT.target_key])] : "${VALID_ELEMENT.cidr}-${VALID_ELEMENT.target_type}" => {cidr = VALID_ELEMENT.cidr, target_id = var.route_targets[VALID_ELEMENT.target_type][VALID_ELEMENT.target_key]} }

# Theme 3: IAM Policy Statement Builder
# -------------------------------------

variable "iam_specs" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
    effect    = string
    condition = optional(map(map(string)))
  }))
  default = [
    {
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::mybucket/*"]
      effect    = "Allow"
    },
    {
      actions   = ["ec2:StartInstances"]
      resources = ["*"]
      effect    = "Deny"
      condition = {
        StringEquals = {
          "aws:RequestedRegion" = "us-west-2"
        }
      }
    }
  ]
}

/* 
Example Output:
[
  {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::mybucket/*"]
    effect    = "Allow"
  },
  {
    actions   = ["ec2:StartInstances"]
    resources = ["*"]
    effect    = "Deny"
    condition = { "StringEquals" = { "aws:RequestedRegion" = "us-west-2" } }
  }
]
*/

/* 
{for KEY, SPEC in var.iam_specs : 
    "rule-${KEY}" => {
        "actions" = SPEC.actions
        "resources" = SPEC.resources
        "effect" =  SPEC.effect
        "condition" = SPEC.condition
    }
}

jsonencode(
    {for KEY, SPEC in var.iam_specs : 
        "rule-${KEY}" => {
            "actions" = SPEC.actions
            "resources" = SPEC.resources
            "effect" =  SPEC.effect
            "condition" = SPEC.condition
        }
    }
)
*/


# Theme 4: Flattening Nested Module Outputs
# 

variable "module_outputs" {
  type = map(map(string))
  default = {
    web = {
      "prod-a" = "subnet-abc"
      "prod-b" = "subnet-def"
    }
    app = {
      "prod-a" = "subnet-ghi"
      "prod-b" = "subnet-jkl"
    }
  }
}

variable "target" {default = "web"}

/* 
{
  "web-prod-a" = "subnet-abc"
  "app-prod-b" = "subnet-def"
}
*/

# familiarise & revise some basic map and list comprehension with this var.module_outputs

# 1. itterate through each key and map, produce new map with keys => maps 'as-is
# > {for key, map in var.module_outputs : key => map}

# 2. a list of maps 
# > [for key, map in var.module_outputs : map]

# 3. filtered list of values, using a literal filter value
# > [for key, map in var.module_outputs : map if key == "web"]

# 4. filtered list of values, using a variable filter value
# > [for key, map in var.module_outputs : map if key == var.target]

# 5. filtered map of values, using a variable filter value
# > {for key, map in var.module_outputs : key => map if key == var.target}

# 6. outer loop to itterate each key and map (like in 1 above), but this time with an inner loop to iterate through each key/value in the map  
# > [for outer_key, map in var.module_outputs : {for inner_key, value in map : "${outer_key}-${inner_key}" => value}]

# 7. same again but this time construct a new map as per the output specification in the example output
# > [for outer_key, map in var.module_outputs : {for inner_key, value in map : "${outer_key}-${inner_key}" => value} if outer_key == var.target]
# this returns a list of maps

# SOLUTION:
# --------- merge with expansion to return a map
# > merge([for outer_key, map in var.module_outputs : {for inner_key, value in map : "${outer_key}-${inner_key}" => value} if outer_key == var.target]...)

# This is the only vialble solution: Terraform doesnt support nested map comprehension so. Such an approach leads to a dead end 
# Example: Below is INVALID syntax: 
# { for outer_key, map in var.module_outputs : { for inner_key, value in map : "${outer_key}-${inner_key}" => value } }
# >> In pseudo code, this is:
# >> { outer map loop : {inner map loop : key => value} }
# This will throw a syntax error Terraform, you can’t directly nest map comprehensions like that.
# In a map comprehension, each iteration must yield exactly one key => value pair — not a whole map.

# this style of nested loops is only valid  for [list comprehensions], where the [outer loop] yields a {map} as its element.
# >> Pseudo code:
# >> [ outer list loop : {inner map loop : key => value} ]

# ----

# there is one alternative which is to pre-select [by index] the target value from the original map
# > {for key, value in var.module_outputs[var.target] : key => value}
# > {for key, value in var.module_outputs[var.target] : "${var.target}-${key}" => value}
# but this is rather a cheat because:
# The exercise is about flattening a nested map structure, and the index expression bypasses that by directly indexing into the target sub-map. 
# That’s efficient, but it skips the flattening logic the exercise is meant to reinforce — namely:
# - Iterating over the outer map
# - Filtering by target
# - Re-keying the inner map entries
# - The earlier merge([...])... solution actually demonstrates that flattening process. This one just shortcuts it.
# ----

# Theme 4: Flattening Nested Module Outputs
# 

variable "module_outputs_4a" {
  type = map(map(string))
  default = {
    web = {
      "prod-a" = "subnet-abc"
      "prod-b" = "subnet-def"
    }
    app = {
      "prod-a" = "subnet-ghi"
      "prod-b" = "subnet-jkl"
    }
    db = {
      "prod-a" = "subnet-mno"
      "prod-b" = "subnet-pqr"
    }
  }
}

variable "target_4a" {
    default = ["web","db"]
}

# test a filter using contains(). filter the map based on list of values in var.target_4a
# > {for key, map in var.module_outputs_4a : key => map if contains(var.target_4a,key)}
# add this new filter to the original map transformation
# > [for outer_key, map in var.module_outputs_4a : {for inner_key, value in map : "${outer_key}-${inner_key}" => value} if contains(var.target_4a,outer_key)]
# merge the result into a flat map of key/value
# > merge([for outer_key, map in var.module_outputs_4a : {for inner_key, value in map : "${outer_key}-${inner_key}" => value} if contains(var.target_4a,outer_key)]...)
