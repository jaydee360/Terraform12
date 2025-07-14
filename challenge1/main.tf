provider "aws" {
    region  = var.aws_region
    profile = var.aws_profile
}

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

variable "vpc_name" {
    description = "the name tag of the vpc"
    type        = string
    default     = "TerraformVPC"
}

variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type = string
    default = "192.168.0.0/24"
}

resource "aws_vpc" "Challenge1VPC" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = var.vpc_name
    }
}
