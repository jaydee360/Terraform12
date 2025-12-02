output "callers" {
  value = {
    general = data.aws_caller_identity.general
    dev = data.aws_caller_identity.dev
    prod = data.aws_caller_identity.prod
  }
}

output "az_us-east-2" {
  value = data.aws_availability_zones.test.names
}

output "aws_ec2_transit_gateway_ids" {
  value = {for k, t in aws_ec2_transit_gateway.main : k => t.id}
}

output "aws_ec2_transit_gateway_route_table_ids" {
  value = {for k, rt in aws_ec2_transit_gateway_route_table.main : k => rt.id}
}

output "aws_ec2_transit_gateway_vpc_attachment_ids" {
  value = {for k, att in aws_ec2_transit_gateway_vpc_attachment.main : k => att.id}
}

output "aws_ec2_transit_gateway_route_table_association_ids" {
  value = {for k, rta in aws_ec2_transit_gateway_route_table_association.main : k => rta.id}
}

output "aws_ec2_transit_gateway_route_table_propagation_ids" {
  value = {for k, rtp in aws_ec2_transit_gateway_route_table_propagation.main : k => rtp.id}
}

output "aws_vpc_ids" {
  value = {for k, v in aws_vpc.main : k => v.id}
  description = "VPC IDs keyed by VPC name"
}

output "aws_subnet_ids_by_routing_policy" {
  value = {
    for grp_key in distinct([for sn_k, sn_o in local.subnet_map : sn_o.routing_policy]) : 
    grp_key => {
        for sn_k, sn_o in local.subnet_map : sn_k => try(aws_subnet.main[sn_k].id, null) if sn_o.routing_policy == grp_key
    }
  }
  description = "Subnet IDs grouped by _routing_policy"
}

output "aws_internet_gateway_ids" {
  value = {for k, igw in aws_internet_gateway.main : k => igw.id }
}

output "aws_internet_gateway_attachment_ids" {
  value = {for k, igw_att in aws_internet_gateway_attachment.main : k => igw_att.id}
}

output "aws_eip_nat_ids" {
  value = {for k, eip in aws_eip.nat : k => eip.id}
  description = "Elastic IP IDs keyed by nat_gw"
}

output "aws_nat_gateway_ids" {
  value = {for k, nat in aws_nat_gateway.main : k => nat.id}
  description = "NAT Gateway IDs keyed by subnet"
}

output "aws_route_table_ids" {
  value = {for k, rt in aws_route_table.main : k => rt.id}
  description = "Route table IDs keyed by route table name"
}

output "aws_route_igw_ids" {
  value = {for k, r in aws_route.igw : k => r.id}  
}

output "aws_route_nat_gw_ids" {
  value = {for k, r in aws_route.nat_gw : k => r.id}  
}

output "aws_networkfirewall_firewall_policy" {
  value = {for k, p in aws_networkfirewall_firewall_policy.main : k => p}  
}

output "aws_networkfirewall_firewall" {
  value = {for k, fw in aws_networkfirewall_firewall.main : k => fw}  
}

output "aws_network_interface_ids" {
  value = {for k, eni in aws_network_interface.main : k => eni.id}
}

output "aws_eip_eni_ids" {
  value = {for k, eip in aws_eip.eni : k => eip.id}
  description = "Elastic IP IDs keyed by ENI"
}

output "aws_instance_ids" {
  value = {for k, i in aws_instance.main : k => i.id}  
}

output "aws_network_interface_attachment_ids" {
  value = {for k, att in aws_network_interface_attachment.main : k => att.id}
}

output "private_key_openssh" {
  value     = tls_private_key.default.private_key_openssh
  sensitive = true
}

output "aws_iam_role" {
  value = {for k, r in aws_iam_role.main: k => {
    id    = r.id
    name  = r.name
  }}
}

output "aws_iam_role_policy_attachment" {
  value = {for k, rpa in aws_iam_role_policy_attachment.main : k => rpa}
}

output "aws_iam_instance_profile" {
  value = {for k, ip in aws_iam_instance_profile.main : k => {
    id    = ip.id
    name  = ip.name
    role  = ip.role
  }}
}

output "aws_cloudwatch_log_groups" {
  value = {
    MAIN = {for k, lg in aws_cloudwatch_log_group.main : k => {
      id        = lg.id
      arn       = lg.arn
      name      = lg.name
      retention = lg.retention_in_days
    }}
    FLOW_LOGS = {for k, lg in aws_cloudwatch_log_group.flow_logs : k => {
      id        = lg.id
      arn       = lg.arn
      name      = lg.name
      retention = lg.retention_in_days
    }}
  }
}


output "aws_iam_policy" {
  value = {for k, p in aws_iam_policy.main : k => {
    id = p.id
    name = p.name
  }}
}

output "aws_iam_role_policy" {
  value = {for k, ilp in aws_iam_role_policy.main: k => {
    id    = ilp.id
    name  = ilp.name
    role  = ilp.role
  }}
}

output "aws_flow_log" {
  value = {for k, fl in aws_flow_log.main : k => fl}
}