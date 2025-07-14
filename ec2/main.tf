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