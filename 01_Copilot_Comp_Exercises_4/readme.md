# Exercise 12: Environment-Specific Resource Aggregation
### Scenario: 
You manage a fleet of resources tagged by environment. You want to group them by environment, but only include environments with more than two resources to reduce dashboard noise.
### Goal: 
Produce a map of environment → list of resource names, excluding environments with ≤2 entries.
### Variable Declaration:
```
variable "resources" {
  default = [
    { name = "db1", env = "prod" },
    { name = "db2", env = "prod" },
    { name = "db3", env = "prod" },
    { name = "web1", env = "dev" },
    { name = "web2", env = "dev" }
  ]
}
```
### Example Output:
```
{
  "prod" = ["db1", "db2", "db3"]
}
```

# Exercise 13: Flattened Routing Table Targets
### Scenario: 
Route definitions are nested under subnet keys. You need to flatten them into a list of route objects, each annotated with its subnet context for module input.

### Goal: 
Transform a map of subnet → route list into a flat list of route objects with subnet metadata.

### Variable Declaration:
```
variable "routes_by_subnet" {
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
```
### Example Output:
```
[
  { subnet = "subnet-a", cidr = "10.0.0.0/16", target = "igw" },
  { subnet = "subnet-a", cidr = "0.0.0.0/0", target = "nat" },
  { subnet = "subnet-b", cidr = "192.168.0.0/16", target = "vpn" }
]
```

# Exercise 14: Semantic Keying with Region and Tier
### Scenario: 
Instances are tagged with region and tier. You want to group them using a semantic key (region:tier) to simplify lookup and monitoring.

### Goal: 
Output a map of "region:tier" → list of instance IDs.

### Variable Declaration:
```
variable "instances" {
  default = [
    { id = "i-abc", region = "us-east-1", tier = "frontend" },
    { id = "i-def", region = "us-east-1", tier = "backend" },
    { id = "i-ghi", region = "us-west-2", tier = "frontend" }
  ]
}
```
### Example Output:
```
{
  "us-east-1:frontend" = ["i-abc"],
  "us-east-1:backend"  = ["i-def"],
  "us-west-2:frontend" = ["i-ghi"]
}
```

# Exercise 15: Conditional Output Shaping
### Scenario: 
Each environment has a map of feature flags. You want to output only the enabled features per environment, and exclude environments with no active features.
### Goal: 
Produce a map of environment → list of enabled feature names.

### Variable Declaration:
```
variable "features_by_env" {
  default = {
    "dev"  = { logging = false, metrics = true },
    "prod" = { logging = false, metrics = false },
    "qa"   = { logging = true, metrics = true }
  }
}
```
### Example Output:
```
{
  "dev" = ["metrics"],
  "qa"  = ["logging", "metrics"]
}
```

# Exercise 16: Reverse Lookup with Metadata Constraints
### Scenario: 
You have a user → role map with metadata. You want to reverse it into a role → list of users, excluding inactive users.
### Goal: 
Build a filtered reverse map of role → active users.
### Variable Declaration:
```
variable "users" {
  default = {
    "alice" = { role = "admin", active = true },
    "bob"   = { role = "editor", active = false },
    "carol" = { role = "admin", active = true }
  }
}
```
### Example Output:
```
{
  "admin" = ["alice", "carol"]
}
```