# Exercise 1: Basic Map Flattening
### Input
`HCL`
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
`HCL`
```
{
  "engineering-alice" = "engineering"
  "engineering-bob"   = "engineering"
  "design-carol"      = "design"
}
```
# Exercise 2: Flatten Nested Subnets
### Input
`HCL`
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
`HCL`
```
{
  "vpc-a-subnet-a1" = "10.0.1.0/24"
  "vpc-a-subnet-a2" = "10.0.2.0/24"
  "vpc-b-subnet-b1" = "10.1.1.0/24"
}
```
# Exercise 3: Gated Inference with Override
### Input
`hcl`
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
`hcl`
```
{
  "subnet-a1" = "public-rt"
  "subnet-a2" = "private-rt"
  "subnet-a3" = "custom-rt-a3"
}
```

# Exercise 4: Conditional Resource Targeting
### Input
`hcl`
```
variable "routes" = [
  { cidr = "0.0.0.0/0", target_type = "igw", target_key = "vpc-a" },
  { cidr = "0.0.0.0/0", target_type = "nat", target_key = "nat-a" },
  { cidr = "10.100.0.0/16", target_type = "tgw", target_key = "tgw-a" }
]
```
### Goal
Produce a map where each key is the CIDR, and each value is the resolved resource ID using conditional logic like:

`hcl`
```
target_id = target_type == "igw" ? aws_internet_gateway.igw[target_key].id : ...
```
You can mock the resource maps like:
`hcl`
```
locals {
  igw = { "vpc-a" = "igw-123" }
  nat = { "nat-a" = "nat-456" }
  tgw = { "tgw-a" = "tgw-789" }
}
```
### Expected Output
`hcl`
```
{
  "0.0.0.0/0-igw" = "igw-123"
  "0.0.0.0/0-nat" = "nat-456"
  "10.100.0.0/16-tgw" = "tgw-789"
}
```