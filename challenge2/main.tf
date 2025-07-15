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

resource "aws_instance" "DB_Server" {
    ami = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    tags = {
      Name = "DB_Server"
    }
}

resource "aws_instance" "Web_Server" {
    ami = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    user_data = file("server-script.sh")
    tags = {
      Name = "Web_Server"
    }
    security_groups = [aws_security_group.Web_Server_SG.name]
    key_name = "A4L"
}

resource "aws_eip" "Web_Server_EIP" {
    instance = aws_instance.Web_Server.id
    tags = {
        Name = "Web_Server_EIP"
    }
}

variable "IngressRules" {
    type    = list(number)
    default = [80, 443]
}

resource "aws_security_group" "Web_Server_SG" {
    name        = "Web_Server_SG"
    vpc_id      = data.aws_vpc.default.id
    dynamic "ingress" {
        for_each = var.IngressRules
        content {
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "DB_Server_Private_IP" {
  value       = aws_instance.DB_Server.private_ip
  description = "The private IP address of the DB_Server instance"
}

output "Web_Server_Public_IP" {
  value       = aws_eip.Web_Server_EIP.public_ip
  description = "The public IP address of the Web_Server instance"
}

output "Web_Server_Public_DNS" {
  value       = aws_eip.Web_Server_EIP.public_dns
  description = "The public DNS address of the Web_Server instance"
}

output "Default_VPC_ID" {
  value       = data.aws_vpc.default.id
  description = "The ID of the default VPC"
}