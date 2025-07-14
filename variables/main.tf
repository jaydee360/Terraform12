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

variable "MyTuple" {
  type = tuple([string, number, string])
  default = ["cat", 1, "dog"]
}

variable "MyObject" {
  type = object({
    name = string,
    port = list(number)
  })
  default = {
    name = "example",
    port = [80, 443]
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.TagList["Name"]
    Environment = var.TagList["Environment"]
    Project = var.TagList["Project"]    
  }
}

output "vpcid" {
  description = "The ID of the created VPC"
  value       = aws_vpc.my_vpc.id
}
output "vpcarn" {
  description = "The ARN of the created VPC"
  value       = aws_vpc.my_vpc.arn
}

