# Theme 1: Subnet Selection for Tiered Deployment
### Goal
Select subnets based on tier (e.g. web, app, db) and environment (prod, dev), then group them by AZ.

### Skills Reinforced:
- Nested filtering
- Grouping by derived keys
- Optional metadata handling

### Variable Declaration
```
variable "subnet_meta_11" {
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
```
Example Output:
```
{
  "a" = ["subnet-web-a", "subnet-app-a"]
  "b" = ["subnet-web-b", "subnet-app-b"]
}
```

# Theme 2: Route Table Generation with Conditional Targets
### Goal
Transform a list of route specs into a map of route blocks, skipping invalid or incomplete entries.

Skills Reinforced:
- Conditional interpolation
- Guarded lookups
- Map construction with compound keys

### Variable Declaration
```
variable "routes_12" {
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

variable "route_targets_12" {
  type = map(map(string))
  default = {
    igw = { "igw-a" = "igw-123" }
    tgw = { "tgw-a" = "tgw-456" }
  }
}
```
Example Output:
```
{
  "10.0.1.0/24-igw" = { cidr = "10.0.1.0/24", target_id = "igw-123" }
  "10.0.2.0/24-tgw" = { cidr = "10.0.2.0/24", target_id = "tgw-456" }
}
```

# Theme 3: IAM Policy Statement Builder
### Goal
Given a list of actions and resources, build a list of IAM statements with optional conditions.

Skills Reinforced:

- Conditional inclusion
- List of maps construction
- Optional field handling

### Variable Declaration
```
variable "iam_specs_13" {
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
```
Example Output:
```
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
```

# Theme 4: Flattening Nested Module Outputs
### Goal
Given a nested structure of module outputs, flatten and re-key them for downstream use.

Skills Reinforced:
- Flattening nested maps/lists
- Re-keying with semantic identifiers
- Handling optional or missing values

### Variable Declaration
```
variable "module_outputs_14" {
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
```
Example Output:
```
{
  "web-prod-a" = "subnet-abc"
  "app-prod-b" = "subnet-def"
}
```

# Theme 4a: Flattening Nested Module Outputs (variation)
### Goal
Given a nested structure of module outputs, filter, flatten and re-key them for downstream use.<br>
A list of filters for the output map is provided in var.target_4a

Skills Reinforced:
- Flattening nested maps/lists
- Re-keying with semantic identifiers
- Handling optional or missing values

### Variable Declaration
```
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
variable "target_4a" {default = ["web","app"]}


```
Example Output:
```
{
  "web-prod-a" = "subnet-abc"
  "web-prod-b" = "subnet-def"
  "app-prod-a" = "subnet-ghi"
  "app-prod-b" = "subnet-jkl"
}
```