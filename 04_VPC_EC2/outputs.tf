/* 
output "DATA_aws_security_group_default" {
  value = {for k, dsg in data.aws_security_group.default : k => dsg.id}
}

output "DATA_aws_route_table_default" {
  value = {for k, drt in data.aws_route_table.default : k => drt.id}
}

output "DEBUG_01_IGW_route_plan__IGW_lookup_failed" {
  value = local.igw_route_plans_without_viable_igw_target
  description = "VPC > Subnet > Routing Polcies requesting 'inject_IGW', where IGW target lookup failed"
}

output "DEBUG_02_Subnets_requesting_NATGW_without_IGW_route" {
   value = local.nat_gw_subnets_without_igw_route
   description = "Subnets requesting a NAT Gateway without a viable Internet Route"
}

output "DEBUG_03_NATGW_route_plan__NATGW_lookup_failed" {
  value = local.nat_gw_route_plans_without_viable_nat_gw_target
  description = "VPC > Subnet > Routing Polcies requesting 'inject_NAT', where NATGW target lookup failed"
}
output "DEBUG_04_Subnets_with_routing_policy_override_success" {
  value = local.subnets_with_routing_policy_override_success
  description = "Subnets with routing policy override, and matching route_table_config"
}

output "DEBUG_05_Subnets_with_routing_policy_override_failure" {
  value = local.subnets_with_routing_policy_override_failure
  description = "Subnets with routing policy override, but with no matching route_table_config"
}

output "DEBUG_06_Disassociated_route_tables" {
  value = local.disassociated_route_tables
  description = "Policy Route Tables with associate_routing_policy == false"
}

output "DEBUG_07_Subnets_associated_with_MAIN_route_table" {
  value = local.subnets_not_in_subnet_route_table_association
  description = "value"
}

output "DEBUG_08_ENI_EIPs_on_subnets_with_no_igw_route" {
  value = local.eni_eips_without_igw_route
  description = "value"
}

# ----------------------------------------------

output "aws_vpc_ids" {
  value = {for k, v in aws_vpc.main : k => v.id}
  description = "VPC IDs keyed by VPC name"
}

output "aws_subnet_ids_by_type" {
  value = {
    public  = {for k, s in aws_subnet.main : k => s.id if lookup(s.tags, "type", "") == "public"}
    private = {for k, s in aws_subnet.main : k => s.id if lookup(s.tags, "type", "") == "private"}
    no_type = {for k, s in aws_subnet.main : k => s.id if !contains(keys(s.tags),"type")}
  }
  description = "Subnet IDs grouped by type"
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

output "aws_route_table_association_ids" {
  value = {for k, rta in aws_route_table_association.main : k => rta.id}
  description = "Route table association IDs keyed by route table name"
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

output "aws_ec2_managed_prefix_list_ids" {
  value = {for k, l in aws_ec2_managed_prefix_list.main : k => l.id}
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

 */