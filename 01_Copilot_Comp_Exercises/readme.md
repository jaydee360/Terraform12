# Exercise 1: Basic Map Flattening
### Input
```
variable "teams" = {
  "engineering" = {
    members = ["alice", "bob"]
  }
  "design" = {
    members = ["carol"]
  }
}
```
### Goal
Produce a flat map where each key is `team-member`, and the value is the `team name`.

### Expected Output
```
{
  "engineering-alice" = "engineering"
  "engineering-bob"   = "engineering"
  "design-carol"      = "design"
}
```
# Exercise 2: Flatten Nested Subnets
### Input
```
variable "vpcs" = {
  "vpc-a" = {
    subnets = {
      "subnet-a1" = { cidr = "10.0.1.0/24" }
      "subnet-a2" = { cidr = "10.0.2.0/24" }
    }
  }
  "vpc-b" = {
    subnets = {
      "subnet-b1" = { cidr = "10.1.1.0/24" }
    }
  }
}
```
### Goal
Create a flat map where each key is `vpc-subnet`, and each value is the `subnet CIDR`.
### Expected Output
```
{
  "vpc-a-subnet-a1" = "10.0.1.0/24"
  "vpc-a-subnet-a2" = "10.0.2.0/24"
  "vpc-b-subnet-b1" = "10.1.1.0/24"
}
```
# Exercise 3: Gated Inference with Override
### Input
```
variable "subnets" = {
  "subnet-a1" = {
    is_public = true
  }
  "subnet-a2" = {
    is_public = false
  }
  "subnet-a3" = {
    is_public = true
    route_table_key = "custom-rt-a3"
  }
}
```
### Goal
Create a map where each key is the subnet name, and each value is the resolved route_table_key. Use lookup() or contains() to apply gated inference.
### Expected Output
```
{
  "subnet-a1" = "public-rt"
  "subnet-a2" = "private-rt"
  "subnet-a3" = "custom-rt-a3"
}
```
# Exercise 4: Conditional Resource Targeting
### Input
```
variable "routes" = [
  { cidr = "0.0.0.0/0", target_type = "igw", target_key = "vpc-a" },
  { cidr = "0.0.0.0/0", target_type = "nat", target_key = "nat-a" },
  { cidr = "10.100.0.0/16", target_type = "tgw", target_key = "tgw-a" }
]
```
### Goal
Produce a map where each key is the CIDR, and each value is the resolved resource ID using conditional logic like:
```
target_id = target_type == "igw" ? aws_internet_gateway.igw[target_key].id : ...
```
You can mock the resource maps like:
```
locals {
    route_targets = {
        igw = { "vpc-a" = "igw-123" }
        nat = { "nat-a" = "nat-456" }
        tgw = { "tgw-a" = "tgw-789" }
    }
}
```
### Expected Output
```
{
  "0.0.0.0/0-igw" = "igw-123"
  "0.0.0.0/0-nat" = "nat-456"
  "10.100.0.0/16-tgw" = "tgw-789"
}
```
# Exercise 5: Conditional Resource Targeting with Semantic Keys
### Goal: 
Create a map that associates each subnet with a route table, using semantic keys like "vpc-a-public" or "vpc-a-private", unless an override is provided.
### Input:
```
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
```
### Challenge: Build a map like:
```
{
  "subnet-a1" = "vpc-a-public"
  "subnet-a2" = "custom-rt-a2"
  ...
}
```
Use conditional logic to prioritize route_table_key if present, otherwise synthesize the semantic key.
# Exercise 6: Reverse Mapping of Resource Associations
### Goal: 
Flip a subnet-to-route-table map into a route-table-to-subnet list.

### Input:
```
locals {
  subnet_to_rt = {
    "subnet-a1" = "rt-1"
    "subnet-a2" = "rt-2"
    "subnet-a3" = "rt-1"
  }
}
```
### Challenge: 
Produce:
```
{
  "rt-1" = ["subnet-a1", "subnet-a3"]
  "rt-2" = ["subnet-a2"]
}
```
Hint: Use merge() and for expressions to accumulate lists.
# Exercise 7: Multi-Stage Lookup with Fallback
### Goal: 
Resolve a target ID from a nested map, falling back to a default if either the outer or inner key is missing.

### Input:
```
locals {
  route_targets_7 = {
    igw = { "vpc-a" = "igw-123" }
    nat = { "nat-a" = "nat-456" }
  }
}
```
### Challenge: For each route:
```
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
```
Build a map like:
```
{
  "10.0.0.0/16-igw" = "igw-123"
  "10.0.1.0/24-tgw" = "default-tgw"
}
```
Use nested lookup() with fallback logic.