 
output "ec2_instances" {
    value = {for each_key, each_value in aws_instance.main : each_key => each_value.id}
}

output "eip_public_ip" {
    value = {for each_key, each_value in aws_eip.main : each_key => each_value.public_ip}
}

output "eip_public_dns" {
    value = {for each_key, each_value in aws_eip.main : each_key => each_value.public_dns}
}

output "security_group_ids" {
    value = {for each_key, each_value in aws_security_group.main : each_key => each_value.id}
}

output "security_group_ingress_rules" {
    value = {for each_key, each_value in aws_vpc_security_group_ingress_rule.main : each_key => each_value.id}
}

output "security_group_egress_rules" {
    value = {for each_key, each_value in aws_vpc_security_group_egress_rule.main : each_key => each_value.id}
}