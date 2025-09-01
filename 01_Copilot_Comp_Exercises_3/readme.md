# 🧩 Theme 5: Semantic Resource Association
### Goal
Given a set of resources and a semantic keying strategy, dynamically associate them based on matching keys.  
The objective is to build a map of associations where each resource is linked to its corresponding target using shared semantic keys.  
Ensure that missing or invalid lookups are safely excluded in the resulting map

### Skills Reinforced
- Multi-stage lookup
- Semantic joins across maps
- Dynamic referencing
- Key normalization

### Why It Fits
You’ve already mastered flattening and re-keying.  
This theme pushes you into relationship modeling, where you must align two separate data sources based on shared keys — a common challenge in modular infrastructure.

### Variable Declarations
```
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
```
### Example Output
```
{
  "r1" = "subnet-abc"
  "r2" = "subnet-def"
  "r3" = "sg-xyz"
}
```

# Theme 6: Conditional Resource Creation
### Goal
Create a list of resource blocks only when certain conditions are met.  
Each block should include required fields and optionally include metadata if present.

### Skills Reinforced
- Conditional inclusion
- Optional field handling
- Dynamic block construction
- Use of can() and try()

### Why It Fits
You’ve shown fluency in filtering and optional logic. This theme tests whether you can turn logic into infrastructure — selectively creating resources based on dynamic conditions.

### Variable Declarations
```
variable "resource_specs_16" {
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
```
### Example Output
```
[
  {
    name = "alpha"
  },
  {
    name     = "gamma"
    metadata = { owner = "team-x" }
  }
]
```

# Theme 7: Output Normalization
### Goal
Take raw module outputs and normalize them into a consistent structure for downstream consumption. Ensure all entries include required fields and default missing values.

### Skills Reinforced
- Type coercion
- Map/list conversion
- Defaulting missing values
- Output standardization

### Why It Fits
You’ve shown a strong instinct for output clarity. This theme lets you refine that instinct into a reusable pattern — ensuring that downstream consumers receive predictable, normalized data.

### Variable Declarations
```
variable "raw_outputs_17" {
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
```
### Example Output
```
{
  "a" = { id = "res-a", region = "us-east-1" }
  "b" = { id = "res-b", region = "us-west-2" }
  "c" = { id = "res-c", region = "us-east-1" }
}
```
Assume "us-east-1" is the default region if none is provided.

# Theme 8: Semantic Output Structuring
### Goal: 
Normalize and reshape output maps to reflect explicit semantic relationships, not just raw data. You’ll move from conditional shaping (Theme 7) to meaningful transformation — where each output reflects a purpose-driven structure.

### 🔧 Input
```
variable "raw_outputs" {
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
  }
}
```

### 🎯 Target Output
```
{
  "r1" = {
    location = "us-east-1"
    label    = "prod"
  }
  "r2" = {
    location = "eu-west-1"
    label    = "dev"
  }
}
```
### 🧠 Challenge
- Rename keys (region → location, tags["env"] → label)
- Inject defaults if missing (region = "us-east-1")
- Extract nested values safely (tags["env"])
- Exclude entries if critical data is missing

### 🧪 Control Gate
Add a control field like ```valid = bool``` and require that only ```valid == true``` entries are included. This tests your ability to gate output based on internal semantics, not just presence.


### 🛠️ Skills Reinforced
- Multi-stage lookup with try() and can()
- Declarative map reconstruction
- Semantic key renaming
- Output filtering based on structural completeness


### If you want to extend this, you could explore:
- Injecting a fallback label = "unknown" if tags.env is missing but valid == true
- Grouping outputs by environment (prod, dev) using nested maps
- Building a routing map keyed by tags.env for downstream module targeting