variable "InstanceName" {
    description = "Name of the EC2 instance"
    type        = string
}

variable "InstanceType" {
    description = "Type of the EC2 instance"
    type        = string
}

variable "InstanceAMI" {
    description = "AMI ID of the EC2 instance"
    type        = string
}

variable "InstanceKeyName" {
    description = "Key pair name for the EC2 instance"
    type        = string
}

resource "aws_instance" "DB" {
    ami = var.InstanceAMI
    instance_type = var.InstanceType
    tags = {
      Name = var.InstanceName
    }
    key_name = var.InstanceKeyName
}

output "DB_Private_IP" {
  value       = aws_instance.DB.private_ip
}