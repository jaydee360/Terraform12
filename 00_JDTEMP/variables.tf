variable "azure_subscription_ids" {
  type = map(string)
  description = "The map of subscription ID's"
}

variable "resource_groups" {
  type = map(object({
    provider_alias = optional(string, "ch-conn-prd")
    region         = optional(string, "uksouth")
    tags = optional(map(string), {
      BusinessOwner = ""
      CostCentre    = ""
      Criticality   = ""
      Environment   = "PRD"
      Role          = ""
      SupportTeam   = ""
      Application   = ""
    })
  }))
}

variable "networks" {
  type = map(object({
    cidr_block = string
    subnets    = map(object({ cidr_block = string }))
  }))
  default = {
    "private" = {
      cidr_block = "10.1.0.0/16"
      subnets = {
        "db1" = {
          cidr_block = "10.1.0.0/24"
        }
        "db2" = {
          cidr_block = "10.1.1.0/24"
        }
      }
    },
    "public" = {
      cidr_block = "10.2.0.0/16"
      subnets = {
        "webserver" = {
          cidr_block = "10.2.1.0/24"
        }
        "email_server" = {
          cidr_block = "10.2.2.0/24"
        }
      }
    }
    "dmz" = {
      cidr_block = "10.3.0.0/16"
      subnets = {
        "firewall" = {
          cidr_block = "10.3.1.0/24"
        }
      }
    }
  }
}

