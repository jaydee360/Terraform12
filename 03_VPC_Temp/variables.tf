variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
  default     = "terraform"
}

variable "default_tags" {
  type = map(string)
  default = {
    "Environment" = "dev"
    "Owner"       = "Jason"
    "Source"      = "default_tags"
  }
}

variable "az_lookup" {
  type = map(map(string))
  default = {
    "us-east-1" = {
      "a" = "us-east-1a"
      "b" = "us-east-1b"
      "c" = "us-east-1c"
      "d" = "us-east-1d"
    }
  }
}

# vpc_config is a map of VPC definitions. Each VPC includes:
# - CIDR block and DNS settings
# - Optional Internet Gateway config
# - A map of named subnets, each with:
#   - CIDR block
#   - Availability Zone
#   - Flags for public exposure, route table, and NAT Gateway
variable "vpc_config" {
  type = map(object({
    vpc_cidr             = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, false)
    tags                 = optional(map(string))
    igw = optional(object({
      create = bool
      attach = bool
      tags   = map(string)
    }))
    subnets = map(object({
      subnet_cidr = string
      az          = string
      is_public   = optional(bool, false)
      has_route_table = optional(bool, false)
      has_nat_gw  = optional(bool, false)
      tags        = optional(map(string))
    }))
  }))
  default = {
    "vpc-lab-dev-000" = {
      vpc_cidr = "10.0.0.0/16"
      tags = {
      }
      igw = {
        create = true
        attach = true
        tags = {
        }
      }
      subnets = {
        "snet-lab-dev-000-a" = {
          az          = "a"
          subnet_cidr = "10.0.0.0/24"
          tags = {
          }
          has_route_table = true
          has_nat_gw = true
        }
        "snet-lab-dev-000-b" = {
          az          = "b"
          subnet_cidr = "10.0.1.0/24"
          tags = {
          }
          has_route_table = true
          has_nat_gw = false
        }
        "snet-lab-dev-000-c" = {
          az          = "c"
          subnet_cidr = "10.0.2.0/24"
          tags = {
          }
          has_route_table = true
          has_nat_gw = false
        }
      }
    }
    "vpc-lab-dev-100" = {
      vpc_cidr = "10.1.0.0/16"
      tags = {
      }
      igw = {
        create = true
        attach = true
        tags = {
        }
      }
      subnets = {
        "snet-lab-dev-100-a" = {
          az          = "a"
          subnet_cidr = "10.1.0.0/24"
          tags = {
          }
          has_route_table = true
          has_nat_gw = false
        }
        "snet-lab-dev-100-b" = {
          az          = "b"
          subnet_cidr = "10.1.1.0/24"
          tags = {
          }
          has_route_table = true
          has_nat_gw = false
        }
      }
    }
  }
}

# route_table_config is a map keyed by "vpc_key__subnet_key"
# Each entry defines:
#   - Whether to inject an IGW route
#   - Whether to inject a NAT route
#   - Optional custom routes (each with CIDR, target type, and target key)
#   - Optional tags for the route table
# Validation ensures:
#   - A route table cannot inject both IGW and NAT simultaneously
variable "route_table_config" {
  type = map(object({
    inject_igw    = optional(bool, false)
    inject_nat    = optional(bool, false)
    custom_routes = optional(list(object({
      cidr_block    = string
      target_type   = string
      target_key    = string
    })))
    tags          = optional(map(string),{})
  }))
  default = {
    "vpc-lab-dev-000__snet-lab-dev-000-a" = {
      inject_igw = true
    }
    "vpc-lab-dev-000__snet-lab-dev-000-c" = {
      inject_nat = true
    }
  }
  validation {
    condition = alltrue([for v in var.route_table_config : 
      !(v.inject_igw && v.inject_nat)
    ])
    error_message = "A route table cannot inject both IGW and NAT. Check: route_table_config."
  }
}



