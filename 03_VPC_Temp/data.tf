data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  for_each = aws_vpc.main
  name     = "default"
  vpc_id   = each.value.id
}

data "aws_route_table" "default" {
  for_each = aws_vpc.main
  filter {
    name = "vpc-id"
    values = [each.value.id]
  }
  filter {
    name = "association.main"
    values = ["true"]
  }
}

data "aws_route_tables" "all" {
  for_each = aws_vpc.main
  filter {
    name = "vpc-id"
    values = [each.value.id]
  }
}

data "aws_route_table" "each" {
  for_each = toset(data.aws_route_tables.all["vpc-lab-dev-000"].ids)
  route_table_id = each.value
}