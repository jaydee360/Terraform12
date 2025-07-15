terraform {
  required_providers {
    aws = {
      version = "6.3.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform"
}

module "ec2module" {
  source   = "./ec2"
  ec2name  = "ModuleTest"
}

output "module_instance_id" {
  value = module.ec2module.instance_id
}
