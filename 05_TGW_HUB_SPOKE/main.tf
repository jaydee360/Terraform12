# module "aws25_dev" {
  #   source = "./modules/tgw"
  #   providers = {aws = aws.aws25_dev}
  #   for_each = {for k, v in var.tgw_config : k => v if v.account == "aws25_dev"}
  #   tgw_key = each.key
  #   tgw_object = each.value
  #   default_tags = var.default_tags
# }

# module "aws25_prod" {
  #   source = "./modules/tgw"
  #   providers = {aws = aws.aws25_prod}
  #   for_each = {for k, v in var.tgw_config : k => v if v.account == "aws25_prod"}
  #   tgw_key = each.key
  #   tgw_object = each.value
  #   default_tags = var.default_tags
# }

resource "aws_ec2_transit_gateway" "main" {
  for_each = local.tgw_map

  region                          = each.value.region
  description                     = each.value.description
  amazon_side_asn                 = each.value.amazon_side_asn
  auto_accept_shared_attachments  = each.value.auto_accept_shared_attachments
  default_route_table_association = each.value.default_route_table_association

  tags = merge(
    {Name = each.key},
    var.default_tags,
    each.value.tags
  )
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  for_each = local.tgw_rt_map

  region = each.value.region
  transit_gateway_id = aws_ec2_transit_gateway.main[each.value.tgw_key].id
  tags = merge(
    {Name = each.key},
    var.default_tags,
    each.value.tags
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  for_each = local.tgw_attachment_map

  region              = each.value.vpc_region
  transit_gateway_id  = aws_ec2_transit_gateway.main[each.value.tgw_key].id
  vpc_id              = aws_vpc.main[each.value.vpc_key].id
  subnet_ids          = [for sn in each.value.subnet_keys : aws_subnet.main[sn].id]
}

resource "aws_ec2_transit_gateway_route_table_association" "main" {
  for_each  = local.tgw_rt_association_map

  region                          = each.value.region
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.main[each.value.tgw_rt_key].id
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.main[each.value.associated_vpc_tgw_att_id].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "main" {
  for_each = local.tgw_rt_propagation_map

  region                          = each.value.region
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.main[each.value.tgw_rt_key].id
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.main[each.value.propagated_vpc_tgw_att_id].id
}

resource "aws_vpc" "main" {
  for_each = var.vpc_config

  region = each.value.region
  cidr_block = each.value.vpc_cidr
  enable_dns_support    = each.value.enable_dns_support
  enable_dns_hostnames  = each.value.enable_dns_hostnames
  tags = merge(
    { Name = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_subnet" "main" {
  for_each = local.subnet_map

  region            = each.value.region
  vpc_id            = aws_vpc.main[each.value.vpc_key].id
  cidr_block        = each.value.subnet_cidr
  availability_zone = each.value.az
  tags = merge(
    { Name = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_internet_gateway" "main" {
  for_each = local.igw_map

  region = each.value.region
  tags = merge(
    { Name = each.key },
    # each.value.tags,
    var.default_tags
  )
}

resource "aws_internet_gateway_attachment" "main" {
  for_each = local.igw_map

  region = each.value.region
  internet_gateway_id = aws_internet_gateway.main[each.key].id
  vpc_id              = aws_vpc.main[each.value.vpc_key].id
}

resource "aws_eip" "nat" {
  for_each      = local.nat_gw_map

  region = each.value.region
  domain        = "vpc"
  tags = merge(
    {Name = each.key},
    each.value.tags,     
    var.default_tags
  )
}

resource "aws_nat_gateway" "main" {
  for_each      = local.nat_gw_map

  region = each.value.region
  subnet_id = aws_subnet.main[each.value.subnet_key].id
  allocation_id = aws_eip.nat[each.key].allocation_id
  tags = merge(
    {Name = each.key},
    each.value.tags,    
    var.default_tags
  )  
}

resource "aws_route_table" "main" {
  for_each = local.route_table_map

  region    = each.value.region
  vpc_id    = aws_vpc.main[each.value.vpc_key].id
  tags = merge(
    { Name = each.key },
    each.value.tags,    
    var.default_tags
  )
}

resource "aws_route" "igw" {
  for_each               = local.igw_route_map

  region                 = each.value.region
  route_table_id         = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  gateway_id             = aws_internet_gateway.main[each.value.target_key].id

  depends_on = [
    aws_internet_gateway_attachment.main
  ]
}

resource "aws_route" "nat_gw" {
  for_each               = local.nat_gw_route_map

  region                 = each.value.region
  route_table_id         = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  nat_gateway_id         = aws_nat_gateway.main[each.value.target_key].id
}

resource "aws_route" "tgw" {
  for_each               = local.tgw_route_map

  region                 = each.value.region
  route_table_id         = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  transit_gateway_id     = aws_ec2_transit_gateway.main[each.value.target_key].id
}

resource "aws_route_table_association" "main" {
  for_each       = local.subnet_route_table_associations

  region         = each.value.region
  subnet_id      = aws_subnet.main[each.value.subnet_id].id
  route_table_id = aws_route_table.main[each.value.route_table_id].id
} 
