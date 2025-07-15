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

resource "aws_instance" "my_instance" {
    ami           = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    tags = {
        Name = "MyFirstTFinstance"
    }
    key_name = "A4L"
    security_groups = [aws_security_group.SSH_Traffic.name]
}

resource "aws_eip" "my_elastic_ip" {
    instance = aws_instance.my_instance.id
    tags = {
        Name = "MyElasticIP"
    }
}

resource "aws_security_group" "SSH_Traffic" {
    name        = "SSH_traffic"
    description = "Allow SSH traffic"
    vpc_id      = "vpc-04b3639556daa69d3"
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["212.56.102.213/32"]
    }
    egress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "EIP" {
    value = aws_eip.my_elastic_ip.public_ip
    description = "The public IP address of the Elastic IP associated with the EC2 instance"
}

output "PublicDNS" {
    value = aws_instance.my_instance.public_dns
    description = "The public DNS of the EC2 instance"
}
