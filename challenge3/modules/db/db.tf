resource "aws_instance" "DB" {
    ami = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    tags = {
      Name = "DB_Server"
    }
}

output "DB_Private_IP" {
  value       = aws_instance.DB.private_ip
}