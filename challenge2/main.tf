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

resource "aws_instance" "DB" {
    ami = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    tags = {
      Name = "DB_Server"
    }
}

resource "aws_instance" "WebServer" {
    ami = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    user_data = file("server-script.sh")
    tags = {
      Name = "WebServer"
    }
    #security_groups = [aws_security_group.WebServer_SG.name]
    vpc_security_group_ids = [aws_security_group.WebServer_SG.id]
    key_name = "A4L"
}

resource "aws_eip" "WebServer_EIP" {
    instance = aws_instance.WebServer.id
    tags = {
        Name = "WebServer_EIP"
    }
}

variable "ingressRules" {
    type    = list(number)
    default = [80, 443]
}

resource "aws_security_group" "WebServer_SG" {
    name        = "WebServer_SG"
    vpc_id      = data.aws_vpc.default.id
    dynamic "ingress" {
        iterator = port
        for_each = var.ingressRules
        content {
            from_port   = port.value
            to_port     = port.value
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

output "DB_Private_IP" {
  value       = aws_instance.DB.private_ip
  description = "The private IP address of the DB_Server instance"
}

output "WebServer_Public_IP" {
  value       = aws_eip.WebServer_EIP.public_ip
  description = "The public IP address of the WebServer instance"
}

output "Web_Public_DNS" {
  value       = aws_eip.WebServer_EIP.public_dns
  description = "The public DNS address of the WebServer instance"
}

output "Default_VPC_ID" {
  value       = data.aws_vpc.default.id
  description = "The ID of the default VPC"
}