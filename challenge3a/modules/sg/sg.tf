variable "ingressRules" {
    type    = list(number)
    default = [80, 443]
}

variable "vpc_id" {
    description = "VPC ID for the security group"
    type        = string
    # No default value means this variable is required
}

resource "aws_security_group" "SG" {
    name        = "My_SG"
    vpc_id      = var.vpc_id
    dynamic "ingress" {
        iterator = port
        for_each = var.ingressRules
        content {
            from_port   = port.value
            to_port     = port.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "SG_ID" {
  value       = aws_security_group.SG.id
  description = "The ID of the security group"
}


