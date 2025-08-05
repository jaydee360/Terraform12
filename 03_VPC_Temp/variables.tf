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
    "Owner" = "Jason"
    "Source" = "default_tags"
  } 
}

variable "vpc_config" {
  type = map(object({
    vpc_cidr = string
    enable_dns_support = optional(bool,true)
    enable_dns_hostnames = optional(bool,false)
    tags = optional(map(string))
    igw = optional(object({
      create = bool
      attach = bool
      tags = map(string)
    }))
    subnets = list(object({
      subnet_cidr = string
      az = string
      is_public = optional(bool,false)
      tags = optional(map(string))
    }))
  }))
  default = {
    "VPC-LAB-DEV-00" = {
      vpc_cidr = "10.0.0.0/16"
      tags = {
        "Name" = "VPC-LAB-DEV-00"
      }
      igw = {
        create = true
        attach = true
        tags = {
        }
      }
      subnets = [
        {
          az = "us-east-1a"
          subnet_cidr = "10.0.0.0/24"
          tags = {
            "Name" = "SUBNET-LAB-DEV-00"
          }
          is_public = true
        },
        {
          az = "us-east-1b"
          subnet_cidr = "10.0.1.0/24"
          tags = {
            "Name" = "SUBNET-LAB-DEV-01"
          }
          is_public = false
        },
        {
          az = "us-east-1c"
          subnet_cidr = "10.0.2.0/24"
          tags = {
            "Name" = "SUBNET-LAB-DEV-02"
          }
          is_public = false
        }
      ]
    }
    "VPC-LAB-DEV-01" = {
      vpc_cidr = "10.1.0.0/16"
      tags = {
        "Name" = "VPC-LAB-DEV-10"
      }
      subnets = [
        {
          az = "us-east-1a"
          subnet_cidr = "10.1.0.0/24"
          tags = {
            "Name" = "SUBNET-LAB-DEV-10"
          }
          is_public = false
        },
        {
          az = "us-east-1b"
          subnet_cidr = "10.1.1.0/24"
          tags = {
            "Name" = "SUBNET-LAB-DEV-11"
          }
          is_public = false
        }
      ]
    }
  }
}

/* 
# First start
{for k, v in var.vpc_config : k => v.subnets}

# get a list of subnets objects from the vpc_config
# actually this returns a list of lists of objects, one separate list for each set of subnets under each vpc
# (yes, even though we are not output the vpc data, the subnet objects are still organised by this hierarchy)
[for vpc_key, vpc_obj in var.vpc_config : vpc_obj.subnets]

# if i want a flat list of the same subnets, removing the vpc grouping, i use the flatten function
flatten([for vpc_key, vpc_obj in var.vpc_config : vpc_obj.subnets])

# next i need start to 'enrich' the list of subnets with additional metadata that i can 'pack' into each subnet object
# this first test is just to make sure i can loop through the subnet objects and try to make sure i can access both 'keys' (index), and values (subnet object data itself)
[for vpc_key, vpc_obj in var.vpc_config : [for subnet_idx, subnets in vpc_obj.subnets : subnets]]
[for vpc_key, vpc_obj in var.vpc_config : [for subnet_idx, subnets in vpc_obj.subnets : subnet_idx]]

# same as above. just to check the flattening of the resulting list of lists
flatten([for vpc_key, vpc_obj in var.vpc_config : [for subnet_idx, subnets in vpc_obj.subnets : subnets]])
flatten([for vpc_key, vpc_obj in var.vpc_config : [for subnet_idx, subnets in vpc_obj.subnets : subnet_idx]])

# now i can practice adding  extra fields into the list of subnets, using value that are available from the 2 leves of list comprehension
# i prefer to use merge, to keep the original object data untouched
[for vpc_key, vpc_obj in var.vpc_config : [for subnet_idx, subnets in vpc_obj.subnets : merge(subnets,{"sid"="${vpc_key}-${subnet_idx}"})]]

# finally i can flatten out
flatten([for vpc_key, vpc_obj in var.vpc_config : [for subnet_idx, subnets in vpc_obj.subnets : merge(subnets,{"sid"="${vpc_key}-${subnet_idx}","vpc"="${vpc_key}"})]])

# i can then use the data in each list item (subnet object) to build a new map, where each item is keyed to the 'sid' 
{for sublist in 
(flatten([for vpc_key, vpc_obj in var.vpc_config : [for subnet_idx, subnets in vpc_obj.subnets : merge(subnets,{"sid"="${vpc_key}-${subnet_idx}","vpc"="${vpc_key}"})]])) : 
"${sublist.sid}" => sublist
}

# make it pretty
{
  for flat_subnet in (flatten(
    [for vpc_key, vpc_obj in var.vpc_config : 
      [for subnet_idx, subnets in vpc_obj.subnets : 
        merge(subnets,{"sid"="${vpc_key}-${subnet_idx}","vpc"="${vpc_key}"})
      ]
    ])
  ) : 
  "${flat_subnet.sid}" => flat_subnet
}
 */
/* 
 [
    for vpc_name, vpc in var.vpc_config : {
      vpc_name = vpc_name
      create   = try(vpc.igw.create, false)
      attach   = try(vpc.igw.attach, false)
      tags     = try(vpc.igw.tags, {})
    }
    if try(vpc.igw.create, false) || try(vpc.igw.attach, false)
  ]

  [for vpc_name, vpc in var.vpc_config : vpc.igw ]
  [for vpc_name, vpc in var.vpc_config : [for k, v in vpc.igw : v if v !=null] ]

[for vpc_name, vpc in var.vpc_config : [for k, v in vpc.igw : v] if vpc.igw !=null ]

[for vpc_name, vpc in var.vpc_config : vpc.igw if vpc.igw !=null ]

[for vpc_key, vpc in var.vpc_config : merge(vpc.igw,{"vpc_key"="${vpc_key}"}) if vpc.igw !=null ]
 */                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  