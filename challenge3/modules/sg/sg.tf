data "aws_vpc" "default" {
  default = true
}

variable "ingressRules" {
    type    = list(number)
    default = [80, 443]
}

variable "sg_vpc_id" {
    description = "VPC ID for the security group"
    type        = string
}

resource "aws_security_group" "MySG" {
    name        = "My_SG"
    vpc_id      = var.sg_vpc_id
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

output "MySG_ID" {
  value       = aws_security_group.MySG.id
  description = "The ID of the security group"
}


