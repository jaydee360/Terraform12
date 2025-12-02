data "aws_caller_identity" "general" {
  provider = aws.aws25_general
}

data "aws_caller_identity" "dev" {
  provider = aws.aws25_dev
}

data "aws_caller_identity" "prod" {
  provider = aws.aws25_prod
}

data "aws_availability_zones" "test" {
  region = "us-east-2"
}

# data "aws_networkfirewall_firewall" "test"

data "aws_security_group" "default" {
  for_each = aws_vpc.main
  name     = "default"
  vpc_id   = each.value.id
  region = each.value.region
}

data "aws_ami" "test" {
  for_each = toset(keys(var.az_lookup))

  region = each.key
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

