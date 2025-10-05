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

output "vpc_ids" {
  value = {for k, v in aws_vpc.main : k => v.id}
  description = "VPC IDs keyed by VPC name"
}

output "subnet_ids_by_type" {
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

output "nat_gateway_ids" {
  value = {for k, nat in aws_nat_gateway.main : k => nat.id}
  description = "NAT Gateway IDs keyed by subnet"
}

output "elastic_ip_ids" {
  value = {for k, eip in aws_eip.nat : k => eip.id}
  description = "Elastic IP IDs keyed by subnet"
}

output "igw_route_ids" {
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