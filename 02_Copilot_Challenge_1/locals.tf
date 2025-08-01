/* 
locals {
  ec2_data = jsondecode(file("ec2_data.json"))
}

locals {
  eip_enabled = {for k, v in var.ec2instances : k => v if v.assign_eip == true}
}

 */

locals {
  ingress_rules = {
    for rule in flatten(
      [for main_key, main_object in var.ec2_security_group_rules : 
        [for rule_index, rules in main_object.ingress : 
          merge(rules,{rule_id="${main_key}-INGRESS-R${rule_index}",main_key=main_key})
        ]
      ]
    ) : rule.rule_id => rule
  }
}

locals {
  egress_rules = {
    for rule in flatten(
      [for main_key, main_object in var.ec2_security_group_rules : 
        [for rule_index, rules in main_object.egress : 
          merge(rules,{rule_id="${main_key}-EGRESS-R${rule_index}",main_key=main_key})
        ]
      ]
    ) : rule.rule_id => rule
  }
}
