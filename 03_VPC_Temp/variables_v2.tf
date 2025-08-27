
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
          az          = "us-east-1a"
          subnet_cidr = "10.0.0.0/24"
          tags = {
          }
          is_public = true
        }
        "snet-lab-dev-000-b" = {
          az          = "us-east-1b"
          subnet_cidr = "10.0.1.0/24"
          tags = {
          }
          is_public = false
        }
        "snet-lab-dev-000-c" = {
          az          = "us-east-1c"
          subnet_cidr = "10.0.2.0/24"
          tags = {
          }
          is_public = false
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
          az          = "us-east-1a"
          subnet_cidr = "10.1.0.0/24"
          tags = {
          }
          is_public = false
        }
        "snet-lab-dev-100-b" = {
          az          = "us-east-1b"
          subnet_cidr = "10.1.1.0/24"
          tags = {
          }
          is_public = false
        }
      }
    }
  }
}


