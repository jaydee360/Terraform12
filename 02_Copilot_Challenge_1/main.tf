locals {
  ec2_data = jsondecode(file("ec2_data.json"))
}

/* resource "aws_instance" "test" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  tags = {
    name = var.name
  }
} */

locals {
  eip_enabled = {for k, v in var.ec2instances : k => v if v.assign_eip == true}
}

resource "aws_instance" "main" {
  for_each = var.ec2instances
  ami = each.value.ami
  instance_type = each.value.instance_type
  tags = {
    Name = each.key
  }
  user_data = each.value.user_data_script != null ? file("${path.module}/${each.value.user_data_script}") : null
}

resource "aws_eip" "main" {
  for_each = local.eip_enabled
  instance = aws_instance.main[each.key].id  
}


