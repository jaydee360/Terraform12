
/* 

variable "security_groups" {
  type = map(object({
    name        = string
    description = string
    vpc_id      = string
    tags        = map(string)
  }))
  default         = {
    "Web"         = {
      name        = "Web-sg"
      description = "Web Server SG"
      vpc_id      = "vpc-04b3639556daa69d3"
      tags        = { Role = "web", Env = "dev"}
    },
    "DB"         = {
      name        = "DB-sg"
      description = "DB Server SG"
      vpc_id      = "vpc-04b3639556daa69d3"
      tags        = { Role = "db", Env = "dev"}
    }
  }
}

variable "security_group_rules" {
  type = map(object({
    from_port = 
    to_port   =
    protocol  =
    cidr_blocks
  }))   
}

security_group_rules = {
  ingress = {
        web = [
                {
                  from_port = 80, 
                  to_port = 80, 
                  protocol = "tcp", 
                  cidr_blocks = ["0.0.0.0/0"]
                }, 
                {
                  from_port = 443, 
                  to_port = 443, 
                  protocol = "tcp", 
                  cidr_blocks = ["0.0.0.0/0"]
                }
              ], 
          db = [ 
                  { 
                    from_port = 5432, 
                    to_port = 5432, 
                    protocol = "tcp",
                    cidr_blocks = ["10.0.0.0/16"] 
                  }, 
                  { 
                    from_port = 22, 
                    to_port = 22, 
                    protocol = "tcp", 
                    cidr_blocks = ["10.0.0.0/16"] 
                  }, 
                  { 
                    from_port = 8080, 
                    to_port = 8080, 
                    protocol = "tcp", 
                    cidr_blocks = ["10.0.0.0/16"] 
                  } 
                ] 
            } 
}


variable security_group_rules {
  type = map(
    type = map(
      type = list(
        type = object (

        )
      )
    )
  )
}
 */
variable "project_name" {
  type = string
  default = "my-app"
}

variable "instance_count" {
  type = number
  default = 3
}

variable "enable_monitoring" {
  type = bool
  default = true
}

# ------

variable "allowed_ips" {
  type = list(string)
  default = [ "10.0.0.1", "10.0.0.2", "10.0.0.3" ]
}

variable "retry_delays" {
  type = list(number)
  default = [1, 5, 10]
}

variable "environment_tags" {
  type = map(string)
  default = {
    "Environment" = "Staging"
    "Team" = "Platform"
  }
}

variable "project_owners" {
  type = map(list(string))
  default = {
    "web"   = [ "alice", "bob" ]
    "data"  = [ "carol" ]
  }
}

variable "db_endpoints_1" {
  type = list(map(any)) # becomes map of strings
  default = [ { "host" = "db1.example.com", port = 5432 },
              { "host" = "db2.example.com", port = 5432 }
  ]
}

variable "db_endpoints_2" {
  type = list(map(any)) # becomes map of numbers
  default = [ { host = 01, port = 5432 },
              { host = 02, port = 5432 }
  ]
}

variable "db_endpoints_3" {
  type = list(object({ # allows specification of object attributes
    host = string
    port = number
  }))
  default = [
    {"host" = "db1.example.com", port = 5432},
    {"host" = "db2.example.com", port = 1234}
  ]
}

# ------ Lists

variable "allowed_ports" {
  type = list(number)
  default = [ 22, 80, 443, 8080 ]
}

variable "feature_toggles" {
  type = list(bool)
  default = [ true, true, false, true ]
}

variable "notification_emails" {
  type = list(string)
  default = [ "ops@example.com", "dev@example.com", "qa@example.com" ]
}

# ------ Maps

variable "subnet_ids" {
  type = map(string)
  default = {
    "public" = "subnet-0123abcd",
    "private" = "subnet-4567efgh"
  }
}

variable "ami_ids" {
  type = map(string)
  default = {
    "linux" = "ami-0a1b2c3d4e5f6g7h",
    "windows" = "ami-1h2g3f4e5d6c7b8a"
  }
}

variable "project_quota" {
  type = map(number)
  default = {
    "dev" = 10,
    "staging" = 20,
    "prod" = 50
  }
}

# ------ Objects

variable "database_config" {
  type = object({
    host = string
    port = number
    username = string
    ssl_enabled = bool
  })
  default = {
    host = "db.example.com"
    port = 5432
    username = "admin"
    ssl_enabled = true
  }
}

variable "certificate" {
  type = object({
    domain = string
    validation_method = string
    ttl = number
  })
  default = {
    domain = "example.com"
    validation_method = "DNS"
    ttl = 300
  }
}

variable "monitoring_config" {
  type = object({
    enabled = bool
    interval = number
    endpoints = string 
  })
  default = {
    enabled = true
    interval = 60
    endpoints = "https://metrics.example.com"
  }
}

# ------------------- Simple Nested-Type Exercises #1

# 1 - List of List of Strings
variable "nested_strings" {
  type = list(    # list of (list of strings)
    list(string)
  )
  default = [
    [ "apple", "banana" ],
    [ "cherry" ]
  ]
}

# 2 - Map of List of Numbers
variable "port_groups" {
  type = map(     # map(key/ value). Values are a lists of numbers (map of (list of numbers))
    list(number)
  )
  default = {
    "web" = [ 80, 443 ]
    "db"  = [ 1633, 5432 ]
  }
}

# 3 - List of Map of Strings
variable "services" {
  type = list(    # list of (map of string)
    map(string)
  )
  default = [
    { "name" = "svc1", "path" = "/api" },
    { "name" = "svc2", "path" = "/auth" }
  ]
}

# 4 - object with a list field
variable "network_config" { 
  type = object({   # object with a single key/value. value is a list of strings 
    subnets = list(string) 
  })
  default = {
    subnets = [ "subnet-0123", "subnet-4567" ],
  }
}

# 5- object with a map field
variable "app_env" {
  type = object({   # object with a single key/value. value is a map of strings 
    settings = map(string)
  })
  default = {
    settings = {
      "LOG_LEVEL" = "DEBUG",
      "TZ" = "UTC"
    }
  }
}

# 6 - map of objects
variable "instance_types" {
  type = map(object({     # map (key/value), value is an object of 2x number fields
    cpu = number,
    memory = number
  }))
  default = {
    "small" = {
      cpu = 1,
      memory = 1024
    },
    "medium" = {
      cpu = 2,
      memory = 2048
    }
  }
}

# 7 - List of Objects with Nested List
variable "servers" {
  type = list(object({
    host = string,
    ports = list(number)
  }))
  default = [
    { "host" = "srv1.example.com", ports = [ 22, 80 ] },
    { "host" = "srv2.example.com", ports = [ 22, 443 ] } 
  ]
}

# ------------------- Simple Nested-Type Exercises #2

# Exercise 1 – Map of Maps of Strings
# Describe user permissions per role, where each role maps to a map of permission→state

variable "user_permissions" {
  type    = map(map(string))
  default = {
    # Fill in two roles, e.g. "alice" and "bob",
    # each mapping to at least two permissions (like read/write).
    "alice" = {"Read"="allow", "Write"="deny", "Execute"="deny"},
    "bob" =  {"Read"="allow", "Write"="allow", "Execute"="allow"}
  }
}

# Exercise 2 – List of Objects (with Nested List)
# Capture regional port assignments: a list of objects, each with a region string and a ports list of numbers.

variable "region_ports" {
  type = list(object({
    region = string
    ports  = list(number)
  }))
  default = [
    # e.g. { region = "us-west-1", ports = [80, 443] }, …
    { region = "us-west-1", ports = [80, 443]}
  ]
}

# Exercise 3 – Map of Lists of Objects
# Group tags by service: a map where each service-name key maps to a list of { key, value } tag objects.

variable "service_tags" {
  type = map(list(object({
    key   = string
    value = string
  })))
  default = {
    # e.g. "web" = [{ key = "env", value = "prod" }], …
    "Web" = [
      { key = "env", value = "prod" }, 
      { key = "tier", value = "fe"},
      { key = "owner", value = "platform-team"}
    ],
    "DB" = [
      { key = "env", value = "prod" }, 
      { key = "tier", value = "data"},
      { key = "owner", value = "data-team"}
    ]
  }
}

# Exercise 4 – Object with Multiple Nested Fields
# Define an application config object containing:
# - name (string)
# - settings (map of lists of strings)
# - features (list of strings)

variable "app_config" {
  type = object({
    name = string
    settings = map(list(string))
    features = list(string)
  })
  default = {
    name = "app1"
    settings = {
      "prod" = [ "account-012", "us-east-1", "large" ]
      "test" = [ "account-345", "eu-west-1", "medium" ]
    },
    features = [ "pr-1232", "pr-1233", "pr-1234" ]
  }
}

# Exercise 5 – List of Tuples
# Record a sequence of daily checkpoints as tuples: [date, count, success_flag].

variable "daily_stats" {
  type = list(tuple([ string, number, bool ]))
  default = [ 
    [ "2025-07-27", 40, false ],
    [ "2025-07-28", 41, false ],
    [ "2025-07-29", 42, false ]
  ]
}


# Exercise 6 – Map of Objects with Nested Objects
# Manage server groups: a map where each group name maps to an object containing a servers list. Each server is an object with host and port.

variable "server_groups" {
  type = map(object({
    servers = list(object({
      host = string
      port = number
    }))
  }))
  default = {
    "group1" = { servers = [ {host="srv-00",port=80}, {host="srv-01",port=80}, {host="srv-02",port=80} ] }
    "group2" = { servers = [ {host="srv-10",port=1633}, {host="srv-11",port=1633} ] }
  }
}

# ------------------------------------------------------
/* New Terraform Variable Declaration Exercises
Let’s deepen your mastery of Terraform’s type system. 
For each exercise below, write a variable block with the appropriate type and a default value matching the description. */

# Exercise 1 – Map of Lists of Strings
# Outline:
# A map where each key is an environment name (e.g., “dev”, “stage”, “prod”).
# Each value is a list of tag strings assigned to that environment.

variable "environments" {
  type = map(list(string))
  default = {
    "dev" = [ "dev-tag-1", "dev-tag-2", "dev-tag-3" ],
    "stage" = [ "stg-tag-1", "stg-tag-2", "stg-tag-3"],
    "prod" = [ "prd-tag-1", "prd-tag-2", "prd-tag-3" ]
  }
}

# Exercise 2 – List of Maps
# Outline:
# A list where each element is a map describing an application log entry.
# Each map has keys:
#  - timestamp (string, ISO 8601)
#  - level (string, e.g., “INFO”, “ERROR”)
#  - message (string)

variable "app_event_log" {
  type = list(map(string))
  default = [
    {
      "timestamp" = "2024-07-23T14:23:00"
      "level" = "INFO"
      "message" = "the system is up"
    },
        {
      "timestamp" = "2024-07-23T14:23:00"
      "level" = "WARN"
      "message" = "the system is unstable"
    },
    {
      "timestamp" = "2024-07-23T14:23:00"
      "level" = "ERROR"
      "message" = "the system is down"
    }
  ]
}

# Exercise 3 – Map of Tuples
# Outline:
# A map where each key is a team name.
# Each value is a tuple with exactly three elements:
#  - cpu_limit (number)
#  - memory_limit (number, in MB)
#  - enabled (bool)

variable "team_limits" {
  type = map(tuple([ number, number,bool ]))
  default = {
    "team-1" = [ 100, 32768, true ]
    "team-2" = [ 50, 16384, true ]
    "team-3" = [ 25, 8192, true]
    "team-4" = [ 12, 4096, false]
  }
}

# Exercise 4 – List of Objects with Nested Fields
# Outline:
# A list of objects, each representing a microservice configuration.
# Object attributes:
# - service_name (string)
# - dependencies (list(string))
# - metadata (object with version (string) and enabled (bool))

variable "microservice_config" {
  type = list(object({
    service_name = string
    dependencies = list(string)
    metadata = object({
      version = string
      enabled = bool 
    })
  }))
  default = [
    { service_name = "order_svc"
      dependencies = [ "basket_svc", "catalog_svc", "payment_svc", "shipping_svc" ]
      metadata = {
        enabled = true
        version = 3
      }
    },
    { service_name = "basket_svc"
      dependencies = [ "order_svc", "catalog_svc" ]
      metadata = {
        enabled = true
        version = 2
      }
    },
    { service_name = "shipping_svc"
      dependencies = [ "order_svc", "logistics_svc" ]
      metadata = {
        enabled = true
        version = 5
      }
    },
    { service_name = "shipping_svc"
      dependencies = [ "order_svc" ]
      metadata = {
        enabled = false
        version = 4
      }
    }
  ]
}

# Exercise 5 – Tuple of Objects
# Outline:
# A tuple with exactly two elements:
# Primary endpoint object
# Backup endpoint object
# Each endpoint object contains:
# - host (string)
# - port (number)

variable "endpoint_services" {
  type = tuple([ 
    object({
      host = string
      port = number
    }),
    object({
      host = string
      port = number
    })
   ])
   default = [ 
    { host = "srv1.example.com", port = 443 }, 
    { host = "srv1a.example.com", port = 443 } 
  ]
}


# Exercise 6 – Object with Complex Nested Structures
# Outline:
# A single object representing a user-directory config.
# Top-level attributes:
# - users (list of objects, each with id (string) and roles (list(string)))
# - defaults (map of string → object with access_level (string) and expires (string, date))

variable "user_dir_config" {
  type = object({
    users = list(object({
      id = string
      roles = list(string)
    })),
    defaults = map(object({
      access_level = string
      expires = string
    }))
  })
  default = {
    users = [
      {
        id = "user1"
        roles = [ "user", "admin" ]
      },
      {
        id = "user2"
        roles = [ "user" ]
      },
      {
        id = "guest"
        roles = [ "guest" ]
      }
    ]
  defaults = {
    "guest" = {
      access_level = "read-only",
      expires = "2025-12-31"
    },
    "user" = {
      access_level = "read-write",
      expires = "2025-12-31"
    },
    "admin" = {
      access_level = "full-control",
      expires = "2025-12-31"      
    }
  }
  }
}

# ------------------------------------------------------
# New Terraform Variable Declaration Exercises

# Exercise 1: Simple List of Strings
# A list of environment names used across your infrastructure.
# Example values: "dev", "staging", "prod"

variable "envs" {
  type = list(string)
  default = [ "dev", "staging", "prod" ]
  validation {
    condition = length(var.envs) > 0
    error_message = "nah!"
  }
}


# Exercise 2: Map of Storage Buckets
# Keys are bucket names.
# Values are objects with:
#  - region (string)
#  - versioning (bool)

variable "buckets" {
  type = map(object({
    region = string
    versioning = bool
  }))
  default = {
    "dev" = {
      region = "us-east-1"
      versioning = false      
    },
    "staging" = {
      region = "us-east-2"
      versioning = false
    },
    "prod" = {
      region = "ap-south-1"
      versioning = true
    }
  }
}

# Exercise 3: Team Directory
# A list of team members.
# Each item is an object with:
#  - id (string)
#  - roles (list of strings)
#  - active (bool)

variable "team_dir" {
  type = list(object({
    id = string
    roles = list(string)
    active = bool
  }))
  default = [ 
    {
      id = "user-1"
      roles = [ "user", "admin" ]
      active = true
    },
    {
      id = "user-2"
      roles = [ "user", "reader" ]
      active = true
    },
    {
      id = "user-3"
      roles = [ "user", "guest" ]
      active = false
    }
  ]
}


# Exercise 4: Network Configuration
# A map of network zones (e.g., "frontend", "backend").
# Each value is an object with:
#  - cidr_block (string)
#  - subnets (map of subnet objects, each with cidr_block as string)

variable "net_config" {
  type = map(object({
    cidr_block = string
    subnets = map(object({
      cidr_block = string
    }))
  }))
  default = {
    frontend = {
      cidr_block = "10.0.1.0/24"
      subnets = {
        subnet-1 = {
          cidr_block = "10.0.1.0/26"
        },
        subnet-2 = {
          cidr_block = "10.0.1.64/26"
        }
      }
    }
    backend = {
      cidr_block = "10.0.2.0/24"
      subnets = {
          subnet-1 = {
          cidr_block = "10.0.2.0/26"
        },
        subnet-2 = {
          cidr_block = "10.0.2.64/26"
        }
      }
    }
  }
}

# Exercise 5: Multi-Region EC2 Spec
# A map where:
# Keys are AWS region names.
# Values are lists of instance configurations.
# Each instance config is an object with:
#  - instance_type (string)
#  - tags (map of string-to-string)

variable "multi_region_ec2_spec" {
  type = map(list(object({
    instance_type = string
    tags = map(string)
  })))
  default = {
    "us-east-1" = [
      {
        instance_type = "t2.nano"
        tags = {
          "desc" = "dev-instance"
          "type" = "nano"
        }
      },
      {
        instance_type = "t2.micro"
        tags = {
          "desc" = "dev-instance"
          "type" = "micro"
        }
      },
      {
        instance_type = "t2.small"
        tags = {
          "desc" = "dev-instance"
          "type" = "small"        
        }
      }
    ]
    "eu-west-1" = [
      {
        instance_type = "t2.medium"
        tags = {
          "desc" = "test-instance"
          "type" = "medium"  
        }
      },
      {
        instance_type = "t2.large"
        tags = {
          "desc" = "test-instance"
          "type" = "large"  
        }
      },
      {
        instance_type = "t2.xlarge"
        tags = {
          "desc" = "test-instance"
          "type" = "xlarge"  
        }
      }
    ]
  }
}

variable "multi_region_ec2_spec_2" {
  type = map(list(object({
    instance_type = string
    tags = map(string)
  })))
  default = {
    "us-east-1" = [for item in ["nano","micro","small"] : {instance_type = "t2.${item}", tags = {type = item, description = "dev-instance"}}]
    "eu-west-1" = [for item in ["medium","large","xlarge"] : {instance_type = "t2.${item}", tags = {type = item, description = "test-instance"}}]
  }
}

# ---------------------------------------------
# More exercises

# Exercise A: API Rate Limit Config
# A map keyed by environment (dev, stage, prod), where each value is an object containing:
# - limit_per_minute (number)
# - burst_size (optional number; default to the same as limit_per_minute)
# - retry_policy (object with max_retries (number) and interval_seconds (number))

variable "api_rate_limit_config" {
  type = map(object({
    limit_per_minute = number
    burst_size = optional(number)
    retry_policy = object({
      max_retries = number
      interval_seconds = number
    }) 
  }))
  default = { # DEFAULT provided for example. NOTE: here 'burst_size' is omitted for 'dev' and 'stage'
    dev = {
      limit_per_minute = 60
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
    stage = {
      limit_per_minute = 90
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
    prod = {
      limit_per_minute = 120
      burst_size = 240
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
  } 
}

variable "api_rate_limit_config_alt" {
  type = map(object({
    limit_per_minute = number
    burst_size = optional(number)
    retry_policy = object({
      max_retries = number
      interval_seconds = number
    }) 
  })) # NO DEFAULT! This variable depends on value supplied from elsewhere (e.g. terraform.tfvars)
}

/*
When you declare a variable as above:
If optional fields are omitted in data, terraform will automatically include them with null values. 
This behavior is part of the variable type system, which normalizes inputs. 
Where 'burst_size' is excluded, we might be surprised to see that the field is still included in the data with burst_size = null.
Terraform ensures structural consistency by injecting burst_size = null.
Hence, when we iterate over var.api_rate_limit_config, values.burst_size will exist with a value of null.
*/

# NOTE: To make "burst_size" (optional) to default to value of "limit_per_minute" if omitted
# - we need to create a local, as below
# - this loops through the default data and modifies it

# Method A (using merge) - UNSAFE
locals {
  api_rate_limit_config_A = {
    for env, values in var.api_rate_limit_config : env => can(values.burst_size) && values.burst_size != null 
    ? values 
    : merge(values,{burst_size=values.limit_per_minute})
  }
}

# Method 2 (rebuild) - SAFE
locals {
  api_rate_limit_config_B = {
    for env, values in var.api_rate_limit_config : env => {
      limit_per_minute = values.limit_per_minute
      burst_size = can(values.burst_size) && values.burst_size != null ? values.burst_size : values.limit_per_minute
      retry_policy = values.retry_policy
    }
  }
}


# The same data declared as a local variable is shown below
# locals are literals. there are NO variable declarations, NO variable type system, 
# There is basically no definition by which to normalize inputs
# Rather obviously in this case, ommitted attributes are ommitted entirely
# use console to look at 
# - "var.api_rate_limit_config" 
#       vs. 
# - "local.api_rate_limit_config_test"
# this will make it completely clear the difference between typed variabes (var.) and untyped (local.)
locals {
  api_rate_limit_config_test = {
    dev = {
      limit_per_minute = 60
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
    stage = {
      limit_per_minute = 90
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
    prod = {
      limit_per_minute = 120
      burst_size = 240
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
  } 
}

/* 
# Loop 1A
{for env, values in var.api_rate_limit_config : env => {
    limit_per_minute = values.limit_per_minute
    burst_size = try (values.burst_size, values.limit_per_minute)
    retry_policy = values.retry_policy
}}
# Loop 1B
{for env, values in var.api_rate_limit_config : env => {
    limit_per_minute = values.limit_per_minute
    burst_size = values.burst_size != null ? values.burst_size : values.limit_per_minute
    retry_policy = values.retry_policy
}}
# Loop 2A
{for env, values in local.api_rate_limit_config_test : env => {
    limit_per_minute = values.limit_per_minute
    burst_size = try (values.burst_size, values.limit_per_minute)
    retry_policy = values.retry_policy
}}
# Loop 2Bv1
{for env, values in local.api_rate_limit_config_test : env => {
    limit_per_minute = values.limit_per_minute
    burst_size = values.burst_size != null ? values.burst_size : values.limit_per_minute
    retry_policy = values.retry_policy
}}
# Loop 2Bv2
{for env, values in local.api_rate_limit_config_test : env => {
    limit_per_minute = values.limit_per_minute
    burst_size = can(values.burst_size) && values.burst_size != null ? values.burst_size : values.limit_per_minute
    retry_policy = values.retry_policy
}}
 */


# ------------------------------- New 31/7/25
# Exercise 7 – Map of Tuples
# Each branch (e.g. "london", "manchester") maps to a fixed structure containing:
# - A satisfaction score (e.g. 8.5)
# - An active status (true or false)

variable "location_rating" {
  type = map(tuple([ number, bool ]))
  default = {
    "london" = [ 8.5, false ]
    "manchester" = [ 9, true]
    "birmingham" = [ 5, true]
  }
}

# Exercise 8 – Object with List of Objects Inside
# Represents a deployment strategy consisting of:
# - A strategy_name string
# - A steps list — each step includes a name string and a duration number

variable "deployment_strategy" {
  type = object({
    strategy_name = string
    strategy_steps = list(object({
      name = string
      duration = number
    }))
  })
  default = {
    strategy_name = "canary"
    strategy_steps = [ 
      { name = "init", duration = 15 },
      { name = "validate", duration = 10 }
    ]
  }
}

# Exercise 9 – List of Maps of Lists
# Each list item is a map associating a student name with a list of enrolled course codes.

variable "student_enrollment" {
  type = list(map(list(string)))
  default = [ 
    { # map students to enrolled courses
      "jason" = [ "MATH101", "CS102" ]
      "alex" = [ "BIO100" ]
      "dave" = [ "ECO200", "PE500"]
    },
    { # weekly course timetable 
      "mon" = [ "MATH101" ]
      "tue" = [ "CS102" ]
      "wed" = [ "BIO100" ]
      "thu" = [ "ECO200" ]
      "fri" = [ "PE500" ]
    } 
  ]
}

# Exercise 10 – Map of Objects with Optional Fields
# Each key represents a cloud account, mapping to:
# - regions: list of region strings
# - tags: map of metadata tags (key→value)
# - owner: string (optional)

variable "cloud_accounts" {
  type = map(object({
    regions = list(string)
    tags = map(string)
    owner = optional(string)
  }))
  default = {
    "dev_acct" = {
      regions = [ "us-east-1" , "us-west-1"]
      tags = {"team": "infra"}
      owner = "jaydee"
    }
    "prod_acct" = {
      regions = [ "eu-west-1", "eu-north-1"]
      tags = {"team": "infra", "env": "prod"}
    }
  }
}

# Exercise 11 – Object with Map of Lists
# Define a variable representing notification preferences. The structure includes:
# - enabled (boolean)
# - channels — a map where each key (like "alerts" or "reports") maps to a list of strings representing delivery methods ("email", "sms", etc.)

variable "notification_prefs" {
  type = object({
    enabled = bool
    channels = map(list(string))
  })
  default = {
    enabled = true
    channels = {
      "alerts" = [ "email", "sms" ]
      "reports" = [ "email", "phone" ]
    }
  }
}

# Exercise 12 – List of Objects Containing Maps
# Each item in the list represents a team, with:
# - name (string)
# - members — a map where each key is a role (like "lead", "developer") and each value is a string for the person assigned

variable "teams" {
  type = list(object({
    name = string
    members = map(string) 
  }))  
  default = [ 
    {
      name = "Team1"
      members = {
        "ops" = "jason"
        "dba" = "tim"
        "dev" = "jim"
      }
    },
    {
      name = "Team2"
      members = {
        "pm" = "anson"
        "arch" = "jay"
        "anal" = "rich"
      }
    }
  ]
}

# Exercise 13 – Map of Maps with Mixed Types
# Track build environments with a top-level map keyed by environment ("dev", "prod"), mapping to another map containing:
# - version (string)
# - ready (bool)
# - attempts (number)

variable "build_envs" {
  type = map(object({
    version = string
    ready = bool
    attempts = number
  }))
  default = {
    "dev" = {
      version = "v1.2a"
      ready = true
      attempts = 3
    }
    "prod" = {
      version = "v1.1"
      ready = true
      attempts = 2 
    }
  }
}


# Exercise 14 – Object with Nested Object and List
# Capture database configuration with:
# - engine (string)
# - options — an object with:
# - encrypted (bool)
# - endpoints (list of strings)

variable "db_config" {
  type = object({
    engine = string
    options = object({
      encrypted = bool
      endpoints = list(string)
    }) 
  })
  default = {
    engine = "mssql"
    options = {
      encrypted = true
      endpoints = [ "ha1.sql.example.com", "ha2.sql.example.com"]
    }
  }
}

# Exercise 15 – List of Tuples Inside a Map
# Each key represents a service name. Each value is a list of tuples: Each tuple contains:
# - string ID
# - numeric weight
# - boolean flag for “critical”

variable "service_values" {
  type = map(list(tuple([ string, number, bool ])))
  default = { 
    main = [
      [ "main01", 1, true],
      [ "main02", 1, true]
    ]
    web = [
      [ "web07", 7, true],
      [ "web08", 8, false]
    ]
  }
}

# Exercise 16 – Map of Objects with Nested Lists of Objects
# Track cloud function deployments per region. Each region (e.g. "us-west-1", "eu-central-1") maps to an object containing:
# - project (string): Name of the project
# - functions — a list of objects, each containing:
#   - name (string): Function name
#   - runtime (string): Runtime environment (e.g., "nodejs18")
#   - memory (number): Memory size in MB
#   - secured (bool): Whether the function requires auth

variable "regional_deployment_tracker" {
  type = map(object({
    project = string
    functions = list(object({
      name = string
      runtime = string
      memory = number
      secured = bool 
    })) 
  }))
  default = {
    "us-west-1" = {
      project = "us_banking_api"
      functions = [
        {
          name = "balance"
          runtime = "nodejs18"
          memory = 4096
          secured = true
        },
        {
          name = "transaction"
          runtime = "nodejs18"
          memory = 4096
          secured = true
        }
      ]
    }
    "eu-central-1" = {
      project = "eu_banking_api"
      functions = [
        {
          name = "auth"
          runtime = "dotnetcore"
          memory = 4096
          secured = true
        },
        {
          name = "online"
          runtime = "dotnetcore"
          memory = 4096
          secured = false
        }
      ]
    }
  }
}

/*
Exercise 17 – Nested Object for VPC Configurations by Environment
Objective: Define variable structure to represent VPC configurations across environments (dev, qa, prod). Each environment should map to an object containing:
- cidr_block (string): The CIDR block of the VPC
- enable_dns_support (bool): Whether DNS support is enabled
- subnets (list of objects): Each subnet object includes:
- - name (string): Subnet name
- - cidr (string): Subnet CIDR block
- - az (string): Availability zone (e.g. "us-east-1a")
- - public (bool): Whether subnet is public

Requirements
- Use a map(object(...)) structure for environments
- Default data should cover at least 2 environments (dev and prod)
- At least 2 subnets per environment with distinct values
*/
variable "vpc_by_env" {
  type = map(object({
    cidr_block = string
    enable_dns_support = bool
    subnets = list(object({
      name = string 
      cidr = string
      az = string
      public = bool
    }))
  }))
  default = {
    "prod" = {
      cidr_block = "10.0.0.0/16"
      enable_dns_support = true
      subnets = [
        {
          name = "web-0a"
          cidr = "10.0.0.0/24"
          az = "az-a"
          public = true
        },
        {
          name = "web-1b"
          cidr = "10.0.1.0/24"
          az = "az-b"
          public = true
        },
        {
          name = "web-2c"
          cidr = "10.0.2.0/24"
          az = "az-c"
          public = true
        },
                {
          name = "priv-4a"
          cidr = "10.0.4.0/24"
          az = "az-a"
          public = false
        },
        {
          name = "priv-5b"
          cidr = "10.0.5.0/24"
          az = "az-b"
          public = false
        },
        {
          name = "priv-6c"
          cidr = "10.0.6.0/24"
          az = "az-c"
          public = false
        }
      ]      
    }
    "dev" = {
      cidr_block = "10.8.0.0/16"
      enable_dns_support = true
      subnets = [
        {
          name = "dev-web-0a"
          cidr = "10.8.0.0/24"
          az = "az-a"
          public = false
        },
        {
          name = "dev-web-1b"
          cidr = "10.8.1.0/24"
          az = "az-b"
          public = false
        },
        {
          name = "dev-priv-4a"
          cidr = "10.8.4.0/24"
          az = "az-a"
          public = false
        },
        {
          name = "dev-priv-5b"
          cidr = "10.8.5.0/24"
          az = "az-b"
          public = false
        },
      ]
    }
  }
}

/*
Exercise 18 – Security Group Rules by Environment and Direction
Objective: Create a variable that captures security group rules, segmented by environment (dev, prod) and direction (ingress, egress). Each rule should include:
- description (string): Brief explanation of the rule
- from_port (number): Starting port
- to_port (number): Ending port
- protocol (string): e.g. "tcp" or "udp"
- cidr_blocks (list of strings): CIDR ranges

Requirements:
- Use nested map(object(...)) structure:
- Top-level key = environment
- Next level = direction (ingress, egress)
- Value = list of rules (objects)
- Include at least 1 ingress and 1 egress rule per environment
- Default data must cover dev and prod
*/

variable "sg_rules_by_env" {
  type = map(object({
    ingress = list(object({
      description = string
      from_port = number
      to_port = number
      protocol = string
      cidr_blocks = list(string)
    }))
    egress = list(object({
      description = string
      from_port = number
      to_port = number
      protocol = string
      cidr_blocks = list(string)
    }))
  }))
  default = {
    "prod" = {
      "ingress" = [
        {
          description = "internet-http"
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_blocks = [ "0.0.0.0/0" ]
        },
        {
          description = "internet-https"
          from_port = 443
          to_port = 443
          protocol = "tcp"
          cidr_blocks = [ "0.0.0.0/0" ]
        }
      ]
      "egress" = [
        {
          description = "internet-any"
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = [ "0.0.0.0/0" ]
        }
      ]
    }
    "dev" = {
      "ingress" = [
        {
          description = "internet-ssh"
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = [ "0.0.0.0/0" ]
        }
      ]
      "egress" = [
        {
          description = "internet-any"
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = [ "0.0.0.0/0" ]
        }
      ]
    }
  }
}

/*
psudocode for the resulting datastructure
{
  "env-1" = {
    "ingress" = [
      {"desc"="abc", "fprt"=nn, "tprt"=nn, "proto"="abc", cidrs=["abc","def"]},
      {"desc"="abc", "fprt"=nn, "tprt"=nn, "proto"="abc", cidrs=["abc","def"]}
    ]
    "egress" = [
      {"desc"="abc", "fprt"=nn, "tprt"=nn, "proto"="abc", cidrs=["abc","def"]}
    ]
  }
  "env-2" = {
    "ingress" = [
      {"desc"="abc", "fprt"=nn, "tprt"=nn, "proto"="abc", cidrs=["abc","def"]},
      {"desc"="abc", "fprt"=nn, "tprt"=nn, "proto"="abc", cidrs=["abc","def"]}
    ]
    "egress" = [
      {"desc"="abc", "fprt"=nn, "tprt"=nn, "proto"="abc", cidrs=["abc","def"]}
    ]
  }
}
*/
