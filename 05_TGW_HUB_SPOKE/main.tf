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
  appliance_mode_support = each.value.tgw_app_mode
}

resource "aws_ec2_transit_gateway_route_table_association" "main" {
  for_each  = local.tgw_rt_association_map

  region                          = each.value.region
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.main[each.value.tgw_rt_key].id
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.main[each.value.associated_vpc_tgw_att_id].id

  lifecycle {
    precondition {
      condition = (each.value.associated_vpc_tgw_att_id != null)
      error_message = <<-EOT
        Invalid TGW Route Table Association
        
        VPC: '${each.value.associated_vpc_name}'
        TGW: '${each.value.tgw_key}'
        
        This VPC is not attached to this TGW.
        
        Check:
        1. Does '${each.value.associated_vpc_name}' exist in vpc_config?
        2. Does it have subnets with routing_policy = 'tgw_attach_*'?
        3. Does that routing_policy reference tgw_key = '${each.value.tgw_key}'?
      EOT
    }
  }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "main" {
  for_each = local.tgw_rt_propagation_map

  region                          = each.value.region
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.main[each.value.tgw_rt_key].id
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.main[each.value.propagated_vpc_tgw_att_id].id

  lifecycle {
    precondition {
      condition = (each.value.propagated_vpc_tgw_att_id != null)
      error_message = <<-EOT
        Invalid TGW Route Table Propagation
        
        VPC: '${each.value.propagated_vpc_name}'
        TGW: '${each.value.tgw_key}'
        
        This VPC is not attached to this TGW.
        
        Check:
        1. Does '${each.value.propagated_vpc_name}' exist in vpc_config?
        2. Does it have subnets with routing_policy = 'tgw_attach_*'?
        3. Does that routing_policy reference tgw_key = '${each.value.tgw_key}'?
      EOT
    }
  }
}

resource "aws_ec2_transit_gateway_route" "main" {
  for_each = local.tgw_rt_static_route_map 

  region                         = each.value.region
  destination_cidr_block         = each.value.destination_prefix
  blackhole                      = each.value.target_key == "blackhole" ? true : false
  transit_gateway_attachment_id  = (each.value.target_key != "blackhole" ? aws_ec2_transit_gateway_vpc_attachment.main[each.value.target_key].id : null)
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main[each.value.rt_key].id
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
  for_each               = local.natgw_route_map

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

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.main
  ]
}

resource "aws_route" "fw" {
  for_each = local.fw_route_map

  region = each.value.region
  route_table_id = aws_route_table.main[each.value.rt_key].id
  destination_cidr_block = each.value.destination_prefix
  vpc_endpoint_id = each.value.target_key

  depends_on = [
    aws_networkfirewall_firewall.main
  ]
}

resource "aws_route_table_association" "main" {
  for_each       = local.subnet_route_table_associations

  region         = each.value.region
  subnet_id      = aws_subnet.main[each.value.subnet_id].id
  route_table_id = aws_route_table.main[each.value.route_table_id].id
} 

resource "aws_networkfirewall_firewall" "main" {
  for_each = var.fw_config

  region = each.value.region
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main[each.value.policy_key].arn
  name = each.key
  vpc_id = aws_vpc.main[each.value.vpc_key].id
  dynamic "subnet_mapping" {
    for_each = each.value.subnet_keys
    content {
      subnet_id = aws_subnet.main["${local.subnet_prefix}${each.value.vpc_key}__${subnet_mapping.value}"].id
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  for_each = var.fw_policy_config

  region = each.value.region
  name = each.key
  firewall_policy {
    stateless_default_actions = each.value.stateless_default_actions
    stateless_fragment_default_actions = each.value.stateless_fragment_default_actions
  }
}

resource "aws_networkfirewall_logging_configuration" "main" {
  for_each = var.fw_config
  
  region = each.value.region
  firewall_arn = aws_networkfirewall_firewall.main[each.key].arn
  
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall[each.key].name
      }
      log_destination_type = "CloudWatchLogs"
      log_type            = "FLOW"  # FLOW logs show all traffic
    }
    
    # Optional: Add ALERT logs too
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alerts[each.key].name
      }
      log_destination_type = "CloudWatchLogs"
      log_type            = "ALERT"  # ALERT logs show rule matches
    }
  }
}

# CloudWatch log groups
resource "aws_cloudwatch_log_group" "firewall" {
  for_each = var.fw_config
  
  region = each.value.region
  name              = "/aws/networkfirewall/${each.key}/flow"
  retention_in_days = 7  
}

resource "aws_cloudwatch_log_group" "firewall_alerts" {
  for_each = var.fw_config

  region = each.value.region
  name              = "/aws/networkfirewall/${each.key}/alert"
  retention_in_days = 7
}

# --------------


resource "aws_network_interface" "main" {
  for_each = local.valid_eni_map

  region                  = each.value.region 
  subnet_id               = aws_subnet.main[each.value.subnet_id].id
  description             = "${each.key}__${each.value.subnet_id}"
  # private_ip_list_enabled = each.value.private_ip_list_enabled
  # private_ip_list         = each.value.private_ip_list
  # private_ips_count       = each.value.private_ips_count
  security_groups           = length(each.value.security_groups) > 0 ? [for sg in each.value.security_groups : aws_security_group.main[sg].id] : [data.aws_security_group.default[each.value.vpc].id]
  tags = merge(
    {Name = each.key},
    each.value.tags,
    var.default_tags
  )
}

resource "aws_eip" "eni" {
  for_each = local.valid_eni_eip_map

  region            = each.value.region 
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

  region                = each.value.region 
  ami                   = each.value.ami
  instance_type         = each.value.instance_type
  key_name              = each.value.key_name
  iam_instance_profile  = each.value.iam_instance_profile
  user_data             = each.value.user_data_script != null ? try(file("${path.module}/${each.value.user_data_script}"), null) : null
  tags = merge(
    {Name = each.key},
    each.value.tags,
    var.default_tags
  )

  primary_network_interface  {
    network_interface_id = aws_network_interface.main[local.ec2_eni_lookup_map[each.key][local.primary_nic_name]].id
  }

  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "aws_network_interface_attachment" "main" {
  for_each = local.valid_eni_attachments

  region        = each.value.region 
  instance_id = aws_instance.main[each.value.instance_id].id
  network_interface_id = aws_network_interface.main[each.value.network_interface_id].id
  device_index = each.value.device_index
}

resource "aws_ec2_managed_prefix_list" "main" {
  for_each        = local.prefix_list_map

  region          = each.value.region 
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

  region        = each.value.region 
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

  region            = each.value.region 
  security_group_id = aws_security_group.main[each.value.sg_key].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
  referenced_security_group_id  = try(aws_security_group.main[each.value.referenced_security_group_id].id, null)
  prefix_list_id                = try(aws_ec2_managed_prefix_list.main[each.value.prefix_list_id].id, null)
  cidr_ipv4                     = each.value.cidr_ipv4
  tags = merge(
    {Name = each.value.description},
    each.value.tags,
    var.default_tags
  )
  lifecycle {
    precondition {
      condition = (
        // SG reference is either null or valid
        (each.value.referenced_security_group_id == null || contains(keys(var.security_groups), each.value.referenced_security_group_id))
        &&
        // Prefix list reference is either null or valid
        (each.value.prefix_list_id == null || contains(keys(var.prefix_list_config), each.value.prefix_list_id))
      )
      error_message = "Security Group: '${each.value.sg_key}', Ingress Rule: '${each.value.rule_set_ref}', has an invalid reference in either: 'referenced_security_group_id' = '${coalesce(each.value.referenced_security_group_id, "null")}', or 'prefix_list' = '${coalesce(each.value.prefix_list_id, "null")}'"
    }
  }
}

resource "aws_vpc_security_group_egress_rule" "main" {
  for_each          = local.egress_rules_map

  region            = each.value.region 
  security_group_id = aws_security_group.main[each.value.sg_key].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
  referenced_security_group_id  = try(aws_security_group.main[each.value.referenced_security_group_id].id, null)
  prefix_list_id                = try(aws_ec2_managed_prefix_list.main[each.value.prefix_list_id].id, null)
  cidr_ipv4                     = each.value.cidr_ipv4
  tags = merge(
    {Name = each.value.description},
    each.value.tags,
    var.default_tags
  )
  lifecycle {
    precondition {
      condition = (
        # SG reference is either null or valid
        (each.value.referenced_security_group_id == null || contains(keys(var.security_groups), each.value.referenced_security_group_id))
        &&
        # Prefix list reference is either null or valid
        (each.value.prefix_list_id == null || contains(keys(var.prefix_list_config), each.value.prefix_list_id))
      )
      error_message = "Security Group: '${each.value.sg_key}', Egress Rule Set: '${each.value.rule_set_ref}', has an invalid reference in either: 'referenced_security_group_id' = '${coalesce(each.value.referenced_security_group_id, "null")}', or 'prefix_list' = '${coalesce(each.value.prefix_list_id, "null")}'"
    }
  }
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "default" {
  for_each = toset(keys(var.az_lookup)) 

  region = each.key
  public_key = tls_private_key.default.public_key_openssh
  key_name = "terraform-default"
}

resource "aws_iam_role" "main" {
  for_each = local.aws_iam_role_map

  name = each.value.name
  description = each.value.description
  assume_role_policy = each.value.assume_role_policy
}

resource "aws_iam_role_policy_attachment" "main" {
  for_each = local.aws_iam_role_policy_attachment_map

  role        = aws_iam_role.main[each.value.role].name
  policy_arn  = each.value.policy_arn
}

resource "aws_iam_instance_profile" "main" {
  for_each = local.aws_iam_instance_profile_map

  name = each.value.name
  role = aws_iam_role.main[each.value.role].name
}