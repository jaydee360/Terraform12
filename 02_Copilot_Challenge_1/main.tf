/* 
resource "aws_instance" "main" {
  for_each = var.ec2instances

  ami = each.value.ami
  instance_type = each.value.instance_type
  user_data = each.value.user_data_script != null ? file("${path.module}/${each.value.user_data_script}") : null
  tags = {
    Name = each.key
  }
}

resource "aws_eip" "main" {
  for_each = local.eip_enabled

  instance = aws_instance.main[each.key].id  
}

resource "aws_security_group" "main" {
  for_each = var.ec2instances

  name = "${each.key}-sg"
  description = "Security Group for ${each.key}"
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = "${each.key}-sg"
  }
}
 */

resource "aws_security_group" "main" {
  for_each = var.ec2_security_groups

  name = "${each.key}-sg"
  description = "${each.value.description}: ${each.key}"
  vpc_id = each.value.vpc_id
  tags = merge(
    var.default_tags,
    each.value.tags,
    {Name = "${each.key}-sg"}
  )
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each = local.ingress_rules

  security_group_id = aws_security_group.main[each.value.main_key].id
  description = each.value.description
  from_port = each.value.from_port
  to_port = each.value.to_port
  ip_protocol = each.value.protocol
  cidr_ipv4 = each.value.cidr_blocks
}