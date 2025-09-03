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



