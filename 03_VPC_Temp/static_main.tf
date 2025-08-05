/* resource "aws_subnet" "jdtest_subnet_1b" {
  vpc_id = aws_vpc.jdtest_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Name"="jdtest_subnet-1b"
    "Env" = "lab"
  }
}  */

 resource "aws_vpc" "jdtest_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name"="jdtest_vpc"
    "Env" = "lab"
  }
}

resource "aws_subnet" "jdtest_subnet_1a" {
  vpc_id = aws_vpc.jdtest_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name"="jdtest_subnet-1a"
    "Env" = "lab"
  }
}

resource "aws_internet_gateway" "jdtest_igw" {
  # vpc_id = aws_vpc.jdtest_vpc.id
}

resource "aws_internet_gateway_attachment" "jdtest_igw_att" {
  vpc_id = aws_vpc.jdtest_vpc.id
  internet_gateway_id = aws_internet_gateway.jdtest_igw.id
} 

resource "aws_eip" "jdtest_eip" {}

resource "aws_nat_gateway" "jdtest_nat_gw" {
  subnet_id = aws_subnet.jdtest_subnet_1a.id
  allocation_id = aws_eip.jdtest_eip.allocation_id
}

resource "aws_route_table" "jdtest_rt" {
  vpc_id =  aws_vpc.jdtest_vpc.id
}

resource "aws_route" "jdtest_rr" {
  route_table_id = aws_route_table.jdtest_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.jdtest_igw.id
}

resource "aws_route_table_association" "jdtest_rt_ass" {
  route_table_id = aws_route_table.jdtest_rt.id
  subnet_id = aws_subnet.jdtest_subnet_1a.id
}

