
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

  vpc_id              = aws_vpc.main[each.value.vpc_key].id
  internet_gateway_id = aws_internet_gateway.main[each.key].id
}

resource "aws_route_table" "public" {
  for_each = local.public_rt_map
  vpc_id   = aws_vpc.main[each.key].id
  tags = merge(
    { "Name" = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_route" "public" {
  for_each               = local.public_rt_map
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[each.key].id
}

resource "aws_route_table_association" "jdtest_rt_ass" {
  for_each       = local.public_subnet_map
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.public[each.value.vpc_key].id
}
