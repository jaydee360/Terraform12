/*

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

*/