/* 
output "instance_ids" {
    value = {for key, instance in aws_instance.main : key => instance.id}
}

output "eip_public_ip" {
    value = {for key, eip in aws_eip.main : key => eip.public_ip}
}

output "eip_public_dns" {
    value = {for key, eip in aws_eip.main : key => eip.public_dns}
}
 */