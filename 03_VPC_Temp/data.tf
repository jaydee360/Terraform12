data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  for_each = aws_vpc.main
  name     = "default"
  vpc_id   = each.value.id
}