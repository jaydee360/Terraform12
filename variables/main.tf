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

# variable "vpc_name" {
#   description = "The name of the VPC"
#   type        = string
#   default     = "MyVPC"
# }

variable "TagList" {
  description = "A list of tags to apply to the VPC"
  type        = map(string)
  default     = {
    Name        = "MyVPC"
    Environment = "Development"
    Project     = "Terraform"
  }
  
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.TagList["Name"]
    Environment = var.TagList["Environment"]
    Project = var.TagList["Project"]    
  }
}

