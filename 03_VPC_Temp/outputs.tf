output "subnets_without_matching_route_tables" {
  value = local.subnets_without_matching_route_tables
  description = "Subnets flagged with has_route_table but missing a corresponding route table config"
}

output "unused_route_tables_without_matching_subnet" {
  value = local.unused_route_tables_without_matching_subnet
  description = "Route table configs that reference subnets not present in vpc_config"
}

output "nat_gw_route_plans_without_viable_nat_gw_target" {
  value = local.nat_gw_route_plans_without_viable_nat_gw_target
  description = "Route plans that inject NAT but fail to resolve a valid NAT Gateway target"
}

output "igw_route_plans_without_viable_igw_target" {
  value = local.igw_route_plans_without_viable_igw_target
  description = "Route plans that inject IGW but the VPC lacks an attached IGW"
}

output "nat_gw_subnets_without_igw" {
  value = local.nat_gw_subnets_without_igw
  description = "Subnets requesting NAT Gateway creation but whose VPC lacks an IGW"
}
