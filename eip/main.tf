provider "aws" {
    region  = "us-east-1"
    profile = "terraform"
}

resource "aws_instance" "my_instance" {
    ami           = "ami-0150ccaf51ab55a51"
    instance_type = "t2.micro"
    tags = {
      Name = "MyFirstTFinstance"
    }
    key_name = "A4L"
}

resource "aws_eip" "my_elastic_ip" {
    instance = aws_instance.my_instance.id
    tags = {
        Name = "MyElasticIP"
    }
}
output "EIP" {
    value = aws_eip.my_elastic_ip.public_ip
    description = "The public IP address of the Elastic IP associated with the EC2 instance"
}
