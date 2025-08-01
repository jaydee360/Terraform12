/* 
locals {
  ec2_data = jsondecode(file("ec2_data.json"))
}

locals {
  eip_enabled = {for k, v in var.ec2instances : k => v if v.assign_eip == true}
}

 */

locals {
  ingress_rules = {for sg_key, sg_rule_type in var.ec2_security_group_rules : sg_key => flatten([for sg_rule_type_key, sg_rule in sg_rule_type : sg_rule if sg_rule_type_key == "ingress"])}
}

locals {
  egress_rules = {for sg_key, sg_rule_type in var.ec2_security_group_rules : sg_key => flatten([for sg_rule_type_key, sg_rule in sg_rule_type : sg_rule if sg_rule_type_key == "egress"])}
}
