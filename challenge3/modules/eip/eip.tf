variable "EC2_InstanceID" {
    description = "ID of the EC2 instance to associate with the EIP"
    type        = string
}

resource "aws_eip" "EIP" {
    instance = var.EC2_InstanceID
    tags = {
        Name = "WebServer_EIP"
    }
}

output "EIP_Public_IP" {
    value       = aws_eip.EIP.public_ip
    description = "The public IP address of the EIP associated with the EC2 instance"
}
output "EIP_Public_DNS" {
    value       = aws_eip.EIP.public_dns
    description = "The public DNS address of the EIP associated with the EC2 instance"
}
