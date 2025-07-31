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