variable "SecurityGroupID" {
    description = "ID of the security group to attach to the EC2 instance"
    type        = string
}

variable "UserDataScriptFile" {
    description = "Path to the user data script file"
    type        = string
}

variable "InstanceName" {
    description = "Name of the EC2 instance"
    type        = string
}

variable "InstanceType" {
    description = "Type of the EC2 instance"
    type        = string
    default     = "t2.micro"
}

variable "InstanceAMI" {
    description = "AMI ID of the EC2 instance"
    type        = string
    default     = "ami-0150ccaf51ab55a51"
}

variable "InstanceKeyName" {
    description = "Key pair name for the EC2 instance"
    type        = string
    default     = "A4L"
}

resource "aws_instance" "WebInstance" {
    ami = var.InstanceAMI
    instance_type = var.InstanceType
    user_data = file(var.UserDataScriptFile)
    tags = {
      Name = var.InstanceName
    }
    vpc_security_group_ids = [var.SecurityGroupID]
    key_name = var.InstanceKeyName
}

output "WebInstanceID" {
    value       = aws_instance.WebInstance.id
    description = "The ID of the WebServer EC2 instance"
}
