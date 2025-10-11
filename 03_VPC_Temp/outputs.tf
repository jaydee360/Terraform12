output "DATA_aws_security_group_default" {
  value = {for k, v in data.aws_security_group.default : k => v.id}
}

output "DEBUG_subnets_without_matching_route_tables" {
  value = local.subnets_without_matching_route_tables
  description = "Subnets flagged with has_route_table but missing a corresponding route table config"
}

output "DEBUG_unused_route_tables_without_matching_subnet" {
  value = local.unused_route_tables_without_matching_subnet
  description = "Route table configs that reference subnets not present in vpc_config"
}

output "DEBUG_nat_gw_route_plans_without_viable_nat_gw_target" {
  value = local.nat_gw_route_plans_without_viable_nat_gw_target
  description = "Route plans that inject NAT but fail to resolve a valid NAT Gateway target"
}

output "DEBUG_igw_route_plans_without_viable_igw_target" {
  value = local.igw_route_plans_without_viable_igw_target
  description = "Route plans that inject IGW but the VPC lacks an attached IGW"
}

output "DEBUG_nat_gw_subnets_without_igw" {
  value = local.nat_gw_subnets_without_igw
  description = "Subnets requesting NAT Gateway creation but whose VPC lacks an IGW"
}

output "aws_vpc_ids" {
  value = {for k, v in aws_vpc.main : k => v.id}
  description = "VPC IDs keyed by VPC name"
}

output "aws_internet_gateway_ids" {
  value = {for k, igw in aws_internet_gateway.main : k => igw.id }
}

output "aws_internet_gateway_attachment_ids" {
  value = {for k, igw_att in aws_internet_gateway_attachment.main : k => igw_att.id}
}

output "aws_subnet_ids_by_type" {
  value = {
    public  = {for k, s in aws_subnet.main : k => s.id if lookup(s.tags, "type", "") == "public"}
    private = {for k, s in aws_subnet.main : k => s.id if lookup(s.tags, "type", "") == "private"}
    no_type = {for k, s in aws_subnet.main : k => s.id if !contains(keys(s.tags),"type")}
  }
  description = "Subnet IDs grouped by type"
}

output "route_table_ids" {
  value = {for k, rt in aws_route_table.main : k => rt.id}
  description = "Route table IDs keyed by route table name"
}

output "route_table_association_ids" {
  value = {for k, rta in aws_route_table_association.main : k => rta.id}
  description = "Route table association IDs keyed by route table name"
}

output "nat_gateway_ids" {
  value = {for k, nat in aws_nat_gateway.main : k => nat.id}
  description = "NAT Gateway IDs keyed by subnet"
}

output "aws_eip_nat_ids" {
  value = {for k, eip in aws_eip.nat : k => eip.id}
  description = "Elastic IP IDs keyed by nat_gw"
}

output "aws_route_igw_ids" {
  value = {for k, r in aws_route.igw : k => r.id}  
}

output "ec2_instance_ids" {
  value = {for k, i in aws_instance.main : k => i.id}  
}

output "aws_security_group_ids" {
  value = {for k, sg in aws_security_group.main: k => sg.id}
}

output "aws_vpc_security_group_ingress_rule_ids" {
  value = {for k, ir in aws_vpc_security_group_ingress_rule.main : k => ir.id}
}

output "aws_vpc_security_group_egress_rule_ids" {
  value = {for k, er in aws_vpc_security_group_egress_rule.main : k => er.id}
}

output "aws_ec2_managed_prefix_list_ids" {
  value = {for k, l in aws_ec2_managed_prefix_list.main : k => l.id}
}

output "aws_network_interface_ids" {
  value = {for k, eni in aws_network_interface.main : k => eni.id}
}

output "aws_network_interface_attachment_ids" {
  value = {for k, att in aws_network_interface_attachment.main : k => att.id}
}

output "aws_eip_eni_ids" {
  value = {for k, eip in aws_eip.eni : k => eip.id}
  description = "Elastic IP IDs keyed by ENI"
}
