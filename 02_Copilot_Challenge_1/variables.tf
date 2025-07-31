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


variable "ec2instances" {
  type = map(object({
    ami = string,
    instance_type = string,
    key_name = string
    assign_eip = optional(bool,false)
    user_data_script = optional(string,null)
  }))
  default = {
    "JD-LAB-WEB-US-E-1" = {
      ami = "ami-0150ccaf51ab55a51"
      instance_type = "t2.micro"
      key_name = "A4L"
      assign_eip = true
      user_data_script = "server-script.sh"
    },
    "JD-LAB-DB-US-E-1" = {
      ami = "ami-0150ccaf51ab55a51"
      instance_type = "t2.micro"
      key_name = "A4L"
    }
  }
}
