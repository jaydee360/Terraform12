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

variable "ingressrules" {
  type    = list(number)
  default = [22, 80, 443]
}

variable "egressrules" {
  type    = list(number)
  default = [22, 443, 25, 3306, 52, 8080]
}

resource "aws_instance" "my_instance" {
  ami           = "ami-0150ccaf51ab55a51"
  instance_type = "t2.micro"
  tags = {
    Name = "MyFirstTFinstance"
  }
  key_name        = "A4L"
  security_groups = [aws_security_group.DynamicRules.name]
}

resource "aws_eip" "my_elastic_ip" {
  instance = aws_instance.my_instance.id
  tags = {
    Name = "MyElasticIP"
  }
}

resource "aws_security_group" "DynamicRules" {
  name        = "SSH_traffic"
  description = "Allow SSH traffic"
  vpc_id      = "vpc-04b3639556daa69d3"
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "egress" {
    iterator = port
    for_each = var.egressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

output "EIP" {
  value       = aws_eip.my_elastic_ip.public_ip
  description = "The public IP address of the Elastic IP associated with the EC2 instance"
}

output "PublicDNS" {
  value       = aws_instance.my_instance.public_dns
  description = "The public DNS of the EC2 instance"
}
