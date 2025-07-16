data "aws_vpc" "default" {
  default = true
}

# variable "SecurityGroupID" {
#     description = "ID of the security group to attach to the EC2 instance"
#     type        = string
# }

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
}

variable "InstanceAMI" {
    description = "AMI ID of the EC2 instance"
    type        = string
}

variable "InstanceKeyName" {
    description = "Key pair name for the EC2 instance"
    type        = string
}

resource "aws_instance" "WEB" {
    ami = var.InstanceAMI
    instance_type = var.InstanceType
    user_data = file(var.UserDataScriptFile)
    tags = {
      Name = var.InstanceName
    }
    vpc_security_group_ids = [module.CreateSG.SG_ID]
    key_name = var.InstanceKeyName
}

output "WEB_InstanceID" {
    value       = aws_instance.WEB.id
    description = "The ID of this EC2 instance"
}

module "CreateEIP" {
  source = "../eip"
  EC2_InstanceID = aws_instance.WEB.id
}

module "CreateSG" {
  source = "../sg"
  ingressRules = [22,80,443]
  vpc_id = data.aws_vpc.default.id
}

output "EIP_Public_IP" {
  value       = module.CreateEIP.EIP_Public_IP
  description = "The public IP address of the EIP associated with the WebServer instance"
}

output "EIP_Public_DNS" {
  value       = module.CreateEIP.EIP_Public_DNS
  description = "The public DNS address of the EIP associated with the WebServer instance"
}
