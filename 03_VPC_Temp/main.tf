
/* resource "aws_vpc" "jdtest_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name"="jdtest_vpc"
    "Env" = "lab"
  }
}

resource "aws_internet_gateway" "jdtest_igw" {
  vpc_id = aws_vpc.jdtest_vpc.id
}

resource "aws_internet_gateway_attachment" "jdtest_igw_att" {
  vpc_id = aws_vpc.jdtest_vpc.id
  internet_gateway_id = aws_internet_gateway.jdtest_igw.id
} */

/* resource "aws_subnet" "jdtest_subnet_1a" {
  vpc_id = aws_vpc.jdtest_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name"="jdtest_subnet-1a"
    "Env" = "lab"
  }
}

resource "aws_subnet" "jdtest_subnet_1b" {
  vpc_id = aws_vpc.jdtest_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Name"="jdtest_subnet-1b"
    "Env" = "lab"
  }
} */

resource "aws_vpc" "main" {
  for_each = var.vpc_config

  cidr_block = each.value.vpc_cidr
  tags = {
    "Name" = each.key
    "Env" = "lab"
  }
}

resource "aws_subnet" "main" {
  for_each = local.subnet_map

  vpc_id = aws_vpc.main[each.value.vpc].id
  cidr_block = each.value.subnet_cidr
  availability_zone = each.value.az
  tags = merge(
    each.value.tags,
    var.default_tags
  )
}

resource "aws_internet_gateway" "main" {
  for_each = local.igw_create_map

  vpc_id = aws_vpc.main[each.key].id
}

resource "aws_internet_gateway_attachment" "main" {
  for_each = local.igw_attach_map

  vpc_id = aws_vpc.main[each.key].id
  internet_gateway_id = aws_internet_gateway.main[each.key].id
}