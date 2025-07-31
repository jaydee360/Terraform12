locals {
  ec2_data = jsondecode(file("ec2_data.json"))
}

locals {
  eip_enabled = {for k, v in var.ec2instances : k => v if v.assign_eip == true}
}

