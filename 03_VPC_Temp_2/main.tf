resource "aws_vpc" "main" {
  # Creates one VPC per entry in var. pc_config, using its CIDR and merged tags.
  # No transformation required. var.vpc_config is structured for direct consumption.
  for_each = var.vpc_config

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
  # Creates one subnet per entry in subnet_map, using its CIDR block, resolved AZ, and parent VPC ID.
  # Tags are composed from subnet name, subnet-specific tags, and global defaults.
  for_each = local.subnet_map

  vpc_id            = aws_vpc.main[each.value.vpc_key].id
  cidr_block        = each.value.subnet_cidr
  availability_zone = each.value.az
  tags = merge(
    { Name = each.value.subnet_key },
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
    { Name = each.key },
    each.value.tags,
    var.default_tags
  )
}

resource "aws_internet_gateway_attachment" "main" {
  # For each entry in igw_attach_map:
  # Attach the IGW to its corresponding VPC
  # Because the IGW and VPC instances are no longer keyed the same vpc_key, we now use 'each.value.vpc_key' to reference the VPC_Key for the attachment
  for_each = local.igw_attach_map

  vpc_id              = aws_vpc.main[each.value.vpc_key].id
  internet_gateway_id = aws_internet_gateway.main[each.key].id
}

resource "aws_eip" "nat" {
  # For each subnet flagged for NAT Gateway:
  # - Allocate an Elastic IP in the VPC domain
  # - Use the subnet key as the resource key
  for_each      = local.nat_gw_map

  domain        = "vpc"
  tags = merge(
    {Name = each.key},
    each.value.tags,     # NOTE: NATGWs & NATGW EIPs are both derived from subnets. Thus tags are inherited from SUBNET
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

  subnet_id = aws_subnet.main[each.value.subnet_id].id
  allocation_id = aws_eip.nat[each.key].allocation_id
  tags = merge(
    {Name = each.key},
    each.value.tags,    # NOTE: NATGWs & NATGW EIPs are both derived from subnets. Thus tags are inherited from SUBNET
    var.default_tags
  )  
}

resource "aws_route_table" "main" {
  # For each route_table_map entry:
  # - Create an aws_route_table resource, in the appropriate parent VPC
  # - The index to the VPC instance ID is contained in the enriched route_table_map data 
  for_each = local.route_table_map

  vpc_id   = aws_vpc.main[each.value.vpc_key].id
  tags = merge(
    { Name = each.key },
    each.value.tags,    # NOTE: Route Tables are derived from subnets. Thus tags are inherited from SUBNET
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

  depends_on = [
    aws_internet_gateway_attachment.main
  ]
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
  # - Subnet flagged with associate_route_table == true
  # - Subnet key exists in route_table_map
  for_each       = local.subnet_route_table_associations

  subnet_id      = aws_subnet.main[each.value.subnet_id].id
  route_table_id = aws_route_table.main[each.value.route_table_id].id
} 

resource "aws_network_interface" "main" {
  for_each = local.valid_eni_map

  subnet_id               = aws_subnet.main[each.value.subnet_id].id
  description             = each.value.description
  private_ip_list_enabled = each.value.private_ip_list_enabled
  private_ip_list         = each.value.private_ip_list
  private_ips_count       = each.value.private_ips_count
  security_groups         = length(each.value.security_groups) > 0 ? [for sg in each.value.security_groups : aws_security_group.main[sg].id] : [data.aws_security_group.default[each.value.vpc].id]
  tags = merge(
    {Name = each.key},
    each.value.tags,
    var.default_tags
  )
}

resource "aws_eip" "eni" {
  for_each = local.valid_eni_eip_map

  domain            = "vpc"
  network_interface = aws_network_interface.main[each.key].id
  tags = merge(
    {Name = each.key},
    each.value.tags,     # NOTE: ENI EIPs are derived from EC2 ENIs. Thus tags are inherited from the EC2 ENI
    var.default_tags
  )
} 

resource "aws_instance" "main" {
  for_each = local.valid_ec2_instance_map

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  user_data     = each.value.user_data_script != null ? try(file("${path.module}/${each.value.user_data_script}"), null) : null
  tags = merge(
    {Name = each.key},
    each.value.tags,
    var.default_tags
  )

  primary_network_interface  {
    network_interface_id = aws_network_interface.main[local.ec2_eni_lookup_map[each.key][local.primary_nic_name]].id
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_interface_attachment" "main" {
  for_each = local.valid_eni_attachments

  instance_id = aws_instance.main[each.value.instance_id].id
  network_interface_id = aws_network_interface.main[each.value.network_interface_id].id
  device_index = each.value.device_index
}

resource "aws_ec2_managed_prefix_list" "main" {
  for_each        = local.prefix_list_map

  name            = each.value.name
  address_family  = each.value.address_family
  max_entries     = each.value.max_entries
  tags = merge(
    {Name = each.key},
    each.value.tags,
    var.default_tags
  )

  dynamic "entry" {
    for_each = each.value.entries

    content {
      cidr        = entry.value.cidr
      description = try(entry.value.description, null)
    }   
  }
}

resource "aws_security_group" "main" {
  for_each = local.valid_security_group_map

  name    = each.key
  vpc_id  = aws_vpc.main[each.value.vpc_id].id
  tags = merge(
    {Name = each.key},
    each.value.tags,
    var.default_tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each          = local.ingress_rules_map

  security_group_id = aws_security_group.main[each.value.sg_key].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  referenced_security_group_id  = try(aws_security_group.main[each.value.referenced_security_group_id].id, null)
  prefix_list_id                = try(aws_ec2_managed_prefix_list.main[each.value.prefix_list_id].id, null)
  cidr_ipv4                     = each.value.cidr_ipv4
  tags = merge(
    {Name = each.value.description},
    each.value.tags,
    var.default_tags
  )
}

resource "aws_vpc_security_group_egress_rule" "main" {
  for_each          = local.egress_rules_map

  security_group_id = aws_security_group.main[each.value.sg_key].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  referenced_security_group_id  = try(aws_security_group.main[each.value.referenced_security_group_id].id, null)
  prefix_list_id                = try(aws_ec2_managed_prefix_list.main[each.value.prefix_list_id].id, null)
  cidr_ipv4                     = each.value.cidr_ipv4
  tags = merge(
    {Name = each.value.description},
    each.value.tags,
    var.default_tags
  )
}

