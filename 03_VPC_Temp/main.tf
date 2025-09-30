resource "aws_vpc" "main" {
  # Creates one VPC per entry in var. pc_config, using its CIDR and merged tags.
  # No transformation required. var.vpc_config is structured for direct consumption.
  for_each = var.vpc_config

  cidr_block = each.value.vpc_cidr
  enable_dns_support    = each.value.enable_dns_support
  enable_dns_hostnames  = each.value.enable_dns_hostnames
  tags = merge(
    { "Name" = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_subnet" "main" {
  # Creates one subnet per entry in subnet_map, using its CIDR block, resolved AZ, and parent VPC ID.
  # Tags are composed from subnet name, subnet-specific tags, and global defaults.
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
  # For each entry in igw_create_map:
  # Create an IGW resource, using the vpc_key as the IGW instance key
  # NOTE: vpc_id is commented out, because IGW attachment is handled separately, allowing conditional control over IGW lifecycle.
  for_each = local.igw_create_map

  # vpc_id            = aws_vpc.main[each.value.vpc_key].id
  tags = merge(
    { "Name" = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_internet_gateway_attachment" "main" {
  # For each entry in igw_attach_map:
  # Attach the IGW to its corresponding VPC
  # Because the IGW and VPC instances are keyed with the vpc_key, this same key can be used to reference both VPC and IGW resource instances
  for_each = local.igw_attach_map

  vpc_id              = aws_vpc.main[each.key].id
  internet_gateway_id = aws_internet_gateway.main[each.key].id
}

resource "aws_eip" "nat" {
  # For each subnet flagged for NAT Gateway:
  # - Allocate an Elastic IP in the VPC domain
  # - Use the subnet key as the resource key
  for_each      = local.nat_gw_map

  domain        = "vpc"
  tags = merge(
    {"Name" = each.key},
    each.value.tags,
    var.default_tags
  )
}

resource "aws_nat_gateway" "main" {
  # For each subnet flagged for NAT Gateway:
  # - Create an aws_nat_gateway resource
  # - Use the subnet key as the resource key for deterministic indexing
  # - The subnet key links the NAT Gateway to:
  #   - Its corresponding subnet (aws_subnet.main)
  #   - Its allocated Elastic IP (aws_eip.nat)
  # - Ensures traceability and alignment across subnet, EIP, and NAT Gateway resources
  for_each      = local.nat_gw_map

  subnet_id = aws_subnet.main[each.key].id
  allocation_id = aws_eip.nat[each.key].allocation_id
}

resource "aws_route_table" "main" {
  # For each route_table_map entry:
  # - Create an aws_route_table resource, in the appropriate parent VPC
  # - The index to the VPC instance ID is contained in the enriched route_table_map data 
  for_each = local.route_table_map

  vpc_id   = aws_vpc.main[each.value.vpc_key].id
  tags = merge(
    { "Name" = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_route" "igw" {
  # Injects default routes into route tables that are flagged for IGW routing.
  # Each route is scoped to its route table and targets the IGW associated with the parent VPC.
  for_each               = local.igw_route_plan

  route_table_id         = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  gateway_id             = aws_internet_gateway.main[each.value.target_key].id
}

resource "aws_route" "nat_gw" {
  # Injects default routes into route tables that are flagged for NAT Gatway routing.
  # Each route is scoped to its route table and targets the best NAT-GW using primary (VPC > AZ) and secondary (VPC Only) lookups.
  for_each               = local.nat_gw_route_plan

  route_table_id         = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  nat_gateway_id         = aws_nat_gateway.main[each.value.target_key].id
}

resource "aws_route_table_association" "main" {
  # Creates a route table association between each subnet and its corresponding route table
  # Eligibility is handled in the local.subnet_route_table_associations
  # - Subnet flagged with has_route_table == true
  # - Subnet key exists in route_table_map
  for_each       = local.subnet_route_table_associations

  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.main[each.value].id
} 

resource "aws_instance" "main" {
  for_each = local.ec2_instance_map

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  associate_public_ip_address = each.value.associate_public_ip_address
  user_data                   = each.value.user_data_script != null ? file("${path.module}/${each.value.user_data_script}") : null
  subnet_id                   = aws_subnet.main[each.value.subnet_id].id

  lifecycle {
    create_before_destroy = true
  }
}