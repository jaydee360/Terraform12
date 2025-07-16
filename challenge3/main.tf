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

data "aws_vpc" "default" {
  default = true
}

module "CreateDbServer" {
  source = "./modules/db"
}

module "CreateSG" {
  source = "./modules/sg"
  ingressRules = [22,80,443]
  sg_vpc_id = data.aws_vpc.default.id
}

module "CreateWebServer" {
   source = "./modules/web"
   SecurityGroupID = module.CreateSG.MySG_ID
   UserDataScriptFile = "server-script.sh"
   InstanceName = "WebServer"
   InstanceType = "t2.micro"
   InstanceAMI = "ami-0150ccaf51ab55a51"
   InstanceKeyName = "A4L"
}

module "EIP" {
  source = "./modules/eip"
  EC2_InstanceID = module.CreateWebServer.WebInstanceID
}

output "DB_Private_IP" {
  value       = module.CreateDbServer.DB_Private_IP
  description = "The private IP address of the DB_Server instance"
}

output "WebServer_EIP_Public_IP" {
  value       = module.EIP.EIP_Public_IP
  description = "The public IP address of the EIP associated with the WebServer instance"
  
}
output "WebServer_EIP_Public_DNS" {
  value       = module.EIP.EIP_Public_DNS
  description = "The public DNS address of the EIP associated with the WebServer instance"
}
