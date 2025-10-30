output "DATA_aws_security_group_default" {
  value = {for k, dsg in data.aws_security_group.default : k => dsg.id}
}

output "DATA_aws_route_table_default" {
  value = {for k, drt in data.aws_route_table.default : k => drt.id}
}

# ----------------------------------------------

output "DEBUG" {
  value = {
    DEBUG_01_IGW_route_plan__IGW_lookup_failed = local.igw_route_plans_without_viable_igw_target
    DEBUG_02_Subnets_requesting_NATGW_without_IGW_route = local.nat_gw_subnets_without_igw_route
    DEBUG_03_NATGW_route_plan__NATGW_lookup_failed = local.nat_gw_route_plans_without_viable_nat_gw_target
    DEBUG_04_peering_route_plans__no_connected_peer = local.peering_route_plans_without_connected_peer
    DEBUG_05_Subnets_associated_with_MAIN_route_table = local.subnets_not_in_subnet_route_table_association
    DEBUG_06_Subnet_resolution_conflict_due_to_nonunique_routing_policy_vpc_az = local.subnet_lookup_conflicts
    DEBUG_07_Dropped_EC2_instances_with_VPC_or_subnet_resolution_failure = local.invalid_ec2_instances_with_mismatched_vpcs_or_subnets
    # --- ENI / SG diagnostics ---
    DEBUG_08_ENI_EIPs_on_subnets_with_no_igw_route = local.eni_eips_without_igw_route
    DEBUG_09_ENIs_with_no_security_group__using_DEFAULT_sg = local.enis_with_no_sg
    DEBUG_10_ENIs_with_invalid_security_groups = local.enis_with_invalid_sgs
    DEBUG_11_ENIs_with_security_group_VPC_misalignment = local.enis_with_sgs_vpc_misalignment
    DEBUG_12_ENIs_with_valid_security_groups = local.enis_with_valid_sgs
    # --- Subnet / SG rules diagnostics ---
    DEBUG_13_Subnet_routing_policy_assignment = local.subnet_routing_policies_by_vpc
    DEBUG_14_Subnet_without_routing_policy_assignment = local.subnets_without_routing_policy
    DEBUG_15_Security_groups_with_invalid_VPC = local.invalid_security_groups
    DEBUG_16_Security_group_rules_by_security_group = local.sg_rules_by_sg
  }
}

# ----------------------------------------------

output "aws_vpc_ids" {
  value = {for k, v in aws_vpc.main : k => v.id}
  description = "VPC IDs keyed by VPC name"
}

output "aws_vpc_peering_connection_ids" {
  value = {for k, p in aws_vpc_peering_connection.requester : k => p.id}
  description = "VPC Peerings keyed by requester__accepter"
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

output "aws_route_peerings_ids" {
  value = {for k, r in aws_route.peerings : k => r.id}
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

