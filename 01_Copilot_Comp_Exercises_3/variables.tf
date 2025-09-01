# Theme 5: Semantic Resource Association
# --------------------------------------

variable "resources" {
  type = map(object({
    type = string
    key  = string
  }))
  default = {
    "r1" = { type = "subnet", key = "prod-a" }
    "r2" = { type = "subnet", key = "prod-b" }
    "r3" = { type = "sg",     key = "prod-a" }
    "r4" = { type = "none",   key = ""}
  }
}

variable "targets" {
  type = map(map(string))
  default = {
    subnet = {
      "prod-a" = "subnet-abc"
      "prod-b" = "subnet-def"
    }
    sg = {
      "prod-a" = "sg-xyz"
    }
  }
}

/* 
# framework for basic map comprehension
{for key, map in var.resources : key => map}
# test target lookup using literals for index
var.targets["subnet"]["prod-a"]
# use the target lookup in the map comprehension, with iteration variables 
{for key, map in var.resources : key => var.targets[map.type][map.key]}
# modify the map comprehension, to handle missing or invalid lookups with safety
{for key, map in var.resources : key => var.targets[map.type][map.key] if can(var.targets[map.type][map.key])}
*/

# Theme 6: Conditional Resource Creation
# --------------------------------------
variable "resource_specs" {
  type = list(object({
    name     = string
    enabled  = bool
    metadata = optional(map(string))
  }))
  default = [
    { name = "alpha", enabled = true },
    { name = "beta",  enabled = false },
    { name = "gamma", enabled = true, metadata = { owner = "team-x" } }
  ]
}

/* 
# solution steps
# --------------
# iterate through each element in the list
[for element in var.resource_specs : element]
# iterate through each element in the list, if enabled
[for element in var.resource_specs : element if element.enabled]
# iterate through each element and reproduce each key/value map in the list, if enabled
[for element in var.resource_specs : {for key, value in element : key => value} if element.enabled]
# iterate through each element and reproduce only the map key "name" in the list, if enabled
[for element in var.resource_specs : {for key, value in element : key => value if key == "name"} if element.enabled]

# got stuck here:
# how do i reconstruct each individual key / value based on charateristics of those keys / values?
# i want:
# name
# metadata (if its not null)

# i tried the expression below but obviously this is the wrong approach. 
[for element in var.resource_specs : {for key, value in element : key => value if lookup(element,"metadata") != null} if element.enabled]
# doing a lookup for the metadata key on the element itself will yield true for each iteration of the inner map loop. which results in a complete rebuild of maps where metadata is present, but nothing at all for maps where metadata is not present

# after some time, i settled on the below approach to exclude (filter out) the keys/values we dont want rather than include the keys/values we do want

# this one exclude null values
[for element in var.resource_specs : {for key, value in element : key => value if value != null} if element.enabled]
# this one exludes null values and the 'enabled' key, which is just there for control 
[for element in var.resource_specs : {for key, value in element : key => value if value != null && key != "enabled"} if element.enabled]

# if null values are acceptable in the output, then thie approach is much more elegant and succinct
[for spec in var.resource_specs : {
  name     = spec.name
  metadata = try(spec.metadata)
} if spec.enabled]

# a final twist on that provides a way to filter out the resulting null
[for spec in var.resource_specs : {
    for k, v in {
        name = spec.name, 
        metadata = spec.metadata
    } : k => v if !(k == "metadata" && v == null)
} if spec.enabled]
 */

# Theme 7: Output Normalization
# -----------------------------

 variable "raw_outputs" {
  type = map(object({
    id     = string
    region = optional(string)
  }))
  default = {
    "a" = { id = "res-a" }
    "b" = { id = "res-b", region = "us-west-2" }
    "c" = { id = "res-c" }
  }
}

/* 
# iterate through each key and object. keep same key but recreate the object key/value using a literal value for testing 
{for key, object in var.raw_outputs : key => {test = "value"}}

# errrr! i dont know what i was trying to do here! this is crazy
# i think that i was trying to construct the entire map expression conditionally, and merge other maps,
# but thats totally malformed
{for key, object in var.raw_outputs : key => {(object.region != null) ? object : merge(object, {"region" = "us-east-1"})}}

# have another go. this is better
{for key, object in var.raw_outputs : key => {
    id      = object.id
    region  = (object.region != null) ? object.region : "us-east-1"
}}
*/

# Theme 8: Semantic Output Structuring
# ------------------------------------

variable "raw_outputs_8" {
  type = map(object({
    id     = string
    region = optional(string)
    tags   = optional(map(string))
    valid  = optional(bool)
  }))
  default = {
    r1 = {
      id     = "i-abc123"
      region = "us-east-1"
      tags   = { env = "prod", owner = "team-a" }
      valid  = true
    }
    r2 = {
      id     = "i-def456"
      region = null
      tags   = { env = "dev" }
      valid  = true
    }
    r3 = {
      id     = "i-ghi789"
      region = "eu-west-1"
      tags   = {}
      valid  = false
    }
    r4 = {
      id     = "i-jkl012"
      tags   = null
      valid  = true
    }
    r5 = {
      id     = "i-mno345"
      tags   = { env = "dev" }
    }
    r6 = {
      id     = "i-pqr678"
      tags   = { env = "dev" }
      valid  = true
    }
    r7 = {
      id     = "i-stu901"
      tags   = { env = "prod" }
      valid  = true
    }
  }
}

variable "envs" {default = ["prod", "test"]}
/* 
# steps
# basic framework for map comprehension. Iterate throught the map and create a new map from the old map
{for key, object in var.raw_outputs_8 : key => object}

# Filter the output map using 'valid' as a control flag. 
# This control gate will exclue either 'false' or 'null' (missig) flags
{for key, object in var.raw_outputs_8 : key => object if object.valid}

# remove the control gate and setup the basic framwork for map reconstruction
{for key, object in var.raw_outputs_8 : key => {id = object.id} }

# restore the control gate filter
{for key, object in var.raw_outputs_8 : key => {id = object.id} if object.valid}

# begin working on the keys/values requried in the actual map reconstruction
# location (region):
{for key, object in var.raw_outputs_8 : key => {location = object.region} if object.valid}

# create logic to substitue a default region if region is null. Use these test cases:
var.raw_outputs_8["r1"]["region"] # ok
var.raw_outputs_8["r2"]["region"] # null
# implement ternary logic to test this:
var.raw_outputs_8["r1"]["region"] != null ? "not null" : "null"
var.raw_outputs_8["r2"]["region"] != null ? "not null" : "null"

# implement this logic in the loop, using iteration variables
{for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
} if object.valid}

# label (tags: env) :
# first, test a method of key access for tags.env. find out what happens for each
var.raw_outputs_8["r1"].tags.env # returns 'prod'
var.raw_outputs_8["r2"].tags.env # returns 'dev'
var.raw_outputs_8["r3"].tags.env # ERROR: map does not have an element with the key "env"
var.raw_outputs_8["r4"].tags.env # ERROR: value is null, so it does not have any attributes

# create a way to handle key access errors safely
can(var.raw_outputs_8["r1"].tags.env) # returns 'true'
can(var.raw_outputs_8["r2"].tags.env) # returns 'true'
can(var.raw_outputs_8["r3"].tags.env) # returns 'false'
can(var.raw_outputs_8["r4"].tags.env) # returns 'false'

# implement ternary logic to lookup the value if safe to do so
can(var.raw_outputs_8["r1"].tags.env) ? var.raw_outputs_8["r1"].tags.env : "unknown" # returns 'prod'
can(var.raw_outputs_8["r2"].tags.env) ? var.raw_outputs_8["r2"].tags.env : "unknown" # returns 'dev'
can(var.raw_outputs_8["r3"].tags.env) ? var.raw_outputs_8["r3"].tags.env : "unknown" # returns 'unknown'
can(var.raw_outputs_8["r4"].tags.env) ? var.raw_outputs_8["r4"].tags.env : "unknown" # returns 'unknown'

# implement this logic in the loop, using iteration variables
{for key, object in var.raw_outputs_8 : key => {
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid}

# combine both keys / values
{for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid}

# sketch an additional object filter as a control gate to exclude objects without tags.env values
# in other words, exclude objects that fail the can() lookup test
{for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if can(object.tags.env)}

# combine both object filters
# SOLTUION:
{for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env)}

# SOLTUION: EXTENSION
# i wanted to include a way to control which envs are included or excluded from output
# added var.envs which holds a list of envs for inclusion
# then added a 3rd gate filter to check 'object.tags.env' against this list, using contains()
# the solution is as follows

{for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env) && contains(var.envs,(object.tags.env))}

# during development my original control gate was a little complex and unreadable
# the VALUE in the "contains(list, VALUE)" tries to do too much at once
# the VALUE here incorporates the safety check, and the lookup. with a fallback string if the safety check fails 
# >> if contains(var.envs,(can(object.tags.env) ? object.tags.env : "nothing"))}
# however its much better, cleaner and more readable to break these into separate tests, and combine them with && logic
 */

/* 
# Grouping outputs by environment (prod, dev) using nested maps
# -------------------------------------------------------------
# the HARD way

# start point
{for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env)}

# extract the distinct envs for grouping
distinct([for k, o in {for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env)} : o.label])

# loop through the env groups as group_key, create new map using each group_key and a "test" value
{for group_key in distinct([for k, o in {for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env)} : o.label]) : group_key => "test"
}

# replace the group_key "test" value with the underlying object
# this requires another instance of the same loop that was used to create the distinct group_keys,
# this time we produce the a list of objects that we match against the group_key, for grouping, or roll-up 
{for group_key in distinct([for k, o in {for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env)} : o.label]) : group_key =>
    merge([for kk, oo in {for key, object in var.raw_outputs_8 : key => {
        location = object.region != null ? object.region : "us-east-1"
        label = can(object.tags.env) ? object.tags.env : "unknown"
    } if object.valid && can(object.tags.env)} : oo if oo.label == group_key ]...)
}

# PROBLEM: the above approach replaces the group_key "test" value only with the underlying OBJECT "oo"
# the object key "kk" (whick holds the original keys r1, r2, r3...) is not preserved and is lost

# there are 2 solutions to this that are explained using the pseudo code below

# Solution 1 
# List of maps
# group_key => [ {...}, {...} ]
# Each item is a single-entry map : {(kk) = oo}
# gives you a list of maps per group — you’d need to merge() later if you want a flat map.
{
  for group_key in distinct([<labels from shaped_candidate_map>]) : group_key => [
    for kk, oo in {<shaped_candidate_map>} : {(kk) = oo}
    if oo.label == group_key
  ]
}

# Solution 2 
# Map of maps
# group_key => { kk => oo }
# Direct map comprehension
# gives you a fully grouped map of maps, keyed by group_key and then by original object key (r1, r2, etc.)
{
  for group_key in distinct([<labels from shaped_candidate_map>]) : group_key => {
    for kk, oo in {<shaped_candidate_map>} : kk => oo
    if oo.label == group_key
  }
}

# Solution 1 - implementation
{for group_key in distinct([for k, o in {for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env)} : o.label]) : group_key => 
    merge([for kk, oo in {for key, object in var.raw_outputs_8 : key => {
        location = object.region != null ? object.region : "us-east-1"
        label = can(object.tags.env) ? object.tags.env : "unknown"
    } if object.valid && can(object.tags.env)} : {(kk) = oo} if oo.label == group_key]...)
}

# Solution 2 - implementation
{for group_key in distinct([for k, o in {for key, object in var.raw_outputs_8 : key => {
    location = object.region != null ? object.region : "us-east-1"
    label = can(object.tags.env) ? object.tags.env : "unknown"
} if object.valid && can(object.tags.env)} : o.label]) : group_key => 
    {for kk, oo in {for key, object in var.raw_outputs_8 : key => {
        location = object.region != null ? object.region : "us-east-1"
        label = can(object.tags.env) ? object.tags.env : "unknown"
    } if object.valid && can(object.tags.env)} : kk => oo if oo.label == group_key}
}
#---------------

# the easy way
locals {
    shaped_candidate_map = {
        for key, object in var.raw_outputs_8 : key => {
            location = object.region != null ? object.region : "us-east-1"
            label = can(object.tags.env) ? object.tags.env : "unknown"
        } if object.valid && can(object.tags.env)
    }
}

# simple list to get the labels from the shaped_candidate_map
[for o in local.shaped_candidate_map : o.label]

# dedupe the labels to make them uniqe
distinct([for o in local.shaped_candidate_map : o.label])

# loop through the unique labels and make a test key expression
{for grp_key in distinct([for o in local.shaped_candidate_map : o.label]) : grp_key => "test" }

# replace the test value with a map of keys and values that match the grp_key
{for grp_key in distinct([for o in local.shaped_candidate_map : o.label]) : grp_key => {
    for kk, oo in local.shaped_candidate_map : kk => oo if oo.label == grp_key
}}
*/

# event easier way
# ----------------

# use var.envs as a gate filter in shaped_candidate_map_2
locals {
    shaped_candidate_map_2 = {
        for key, object in var.raw_outputs_8 : key => {
            location = object.region != null ? object.region : "us-east-1"
            label = can(object.tags.env) ? object.tags.env : "unknown"
        } if object.valid && can(object.tags.env) && contains(var.envs,(object.tags.env))
    }
}

# use the same var.envs as a source for group keys
/* 
{for env in var.envs : env => {
    for kk, oo in local.shaped_candidate_map_2 : kk => oo if oo.label == env
}}
 */

 