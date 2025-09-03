
resource "aws_vpc" "main" {
  for_each = var.vpc_config

  cidr_block = each.value.vpc_cidr
  tags = merge(
    { "Name" = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_subnet" "main" {
  for_each = local.subnet_map

  vpc_id            = aws_vpc.main[each.value.vpc_key].id
  cidr_block        = each.value.subnet_cidr
  availability_zone = each.value.az
  tags = merge(
    { "Name" = each.value.subnet_key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_internet_gateway" "main" {
  for_each = local.igw_create_map
  # commented out the vpc_id because we are controlling igw attachment in a seperate resource block
  # vpc_id            = aws_vpc.main[each.value.vpc_key].id
  tags = merge(
    { "Name" = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_internet_gateway_attachment" "main" {
  for_each = local.igw_attach_map

  vpc_id              = aws_vpc.main[each.key].id
  internet_gateway_id = aws_internet_gateway.main[each.key].id
}

resource "aws_eip" "nat" {
  for_each      = local.nat_gw_map
  domain        = "vpc"
  tags = merge(
    {"Name" = each.key},
    each.value.tags,
    var.default_tags
  )
}

resource "aws_nat_gateway" "main" {
  for_each      = local.nat_gw_map
  subnet_id = aws_subnet.main[each.key].id
  allocation_id = aws_eip.nat[each.key].allocation_id
}

resource "aws_route_table" "main" {
  for_each = local.route_table_map
  vpc_id   = aws_vpc.main[each.value.vpc_key].id
  tags = merge(
    { "Name" = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_route" "igw" {
  for_each               = local.igw_route_plan
  route_table_id         = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  gateway_id             = aws_internet_gateway.main[each.value.target_key].id
}

resource "aws_route" "nat_gw" {
  for_each               = local.nat_gw_route_plan
  route_table_id         = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  nat_gateway_id         = aws_nat_gateway.main[each.value.target_key].id
}

resource "aws_route_table_association" "main" {
  for_each       = toset(local.subnet_route_table_associations)
  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.main[each.value].id
} 