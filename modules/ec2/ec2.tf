variable "ec2name" {
    description = "Name of the EC2 instance"
    type        = string
}    

resource "aws_instance" "ec2" {
    ami = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    tags = {
        Name = var.ec2name
    }
}