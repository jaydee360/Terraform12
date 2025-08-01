variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
  default     = "terraform"  
}

variable "default_tags" {
  type = map(string)
  default = {
    "Environment" = "dev"
    "Owner" = "Jason"
    "Source" = "default_tags"
  } 
}

variable "ec2_instances" {
  type = map(object({
    ami = string,
    instance_type = string,
    key_name = string
    assign_eip = optional(bool,false)
    assign_sg = optional(bool,false)
    user_data_script = optional(string,null)
  }))
  default = {
    "JD-LAB-WEB-US-E-1" = {
      ami = "ami-0150ccaf51ab55a51"
      instance_type = "t2.micro"
      key_name = "A4L"
      assign_eip = true
      user_data_script = "server-script.sh"
    },
    "JD-LAB-DB-US-E-1" = {
      ami = "ami-0150ccaf51ab55a51"
      instance_type = "t2.micro"
      key_name = "A4L"
      assign_sg = true
    }
  }
}

variable "ec2_security_groups" {
  type = map(object({
    description = string
    vpc_id = optional(string)
    tags = optional(map(string))
  }))
  default = {
    "JD-LAB-WEB-US-E-1" = {
      description = "From var.ec2_security_groups"
      tags = {
        "Source" = "from-map"
      }      
    }
    "JD-LAB-DB-US-E-1" = {
      description = "From var.ec2_security_groups"   
    }
  }
}

variable "ec2_security_group_rules" {
type = map(object({
    ingress = list(object({
      description = string
      from_port = number
      to_port = number
      protocol = string
      cidr_block = string
    }))
    egress = list(object({
      description = string
      from_port = optional(number)
      to_port = optional(number)
      protocol = string
      cidr_block = string
    }))
  }))
  default = {
    "JD-LAB-WEB-US-E-1" = {
      ingress = [
        {
          description = "80-IN"
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_block =  "0.0.0.0/0" 
        },
        {
          description = "443-IN"
          from_port = 443
          to_port = 443
          protocol = "tcp"
          cidr_block =  "0.0.0.0/0" 
        }
      ]
      egress = [
        {
          description = "ANY-OUT"
          protocol = "-1"
          cidr_block =  "0.0.0.0/0" 
        }
      ]
    },
    "JD-LAB-DB-US-E-1" = {
      ingress = [
        {
          description = "1433-IN"
          from_port = 1433
          to_port = 1433
          protocol = "tcp"
          cidr_block =  "10.0.0.0/16" 
        },
        {
          description = "3389-IN"
          from_port = 3389
          to_port = 3389
          protocol = "tcp"
          cidr_block =  "10.0.0.0/16" 
        }
      ]
      egress = [
        {
          description = "ANY-OUT"
          protocol = "-1"
          cidr_block =  "0.0.0.0/0" 
        }
      ]
    }
  }
}
/* 
{for sg_key, sg_rule_type in var.ec2_security_group_rules : sg_key => [for sg_rule_type_key, sg_rule in sg_rule_type : sg_rule if sg_rule_type_key == "ingress"]}
{for sg_key, sg_rule_type in var.ec2_security_group_rules : sg_key => [for sg_rule_type_key, sg_rule in sg_rule_type : sg_rule if sg_rule_type_key == "egress"]}

{for sg_key, sg_rule_type in var.ec2_security_group_rules : sg_key => flatten([for sg_rule_type_key, sg_rule in sg_rule_type : sg_rule if sg_rule_type_key == "ingress"])}
{for sg_key, sg_rule_type in var.ec2_security_group_rules : sg_key => flatten([for sg_rule_type_key, sg_rule in sg_rule_type : sg_rule if sg_rule_type_key == "egress"])}

{
  "JD-LAB-WEB-US-E-1":[
    {"cidr_blocks":["0.0.0.0/0"],"description":"80-IN","from_port":80,"protocol":"tcp","to_port":80},
    {"cidr_blocks":["0.0.0.0/0"],"description":"443-IN","from_port":443,"protocol":"tcp","to_port":443}
  ]
} */

/*
# step 1 - list comprehension to get ingress & egress rules separately from the data
[for main_key, main_object in var.ec2_security_group_rules : [for rules in main_object.ingress : rules]]
[for main_key, main_object in var.ec2_security_group_rules : [for rules in main_object.egress : rules]]

[for main_key, main_object in var.ec2_security_group_rules : [for rule_index, rules in main_object.ingress : merge(rules,{id="${main_key}>R${rule_index}"})]]
[for main_key, main_object in var.ec2_security_group_rules : [for rule_index, rules in main_object.egress : merge(rules,{id="${main_key}>R${rule_index}"})]]

flatten([for main_key, main_object in var.ec2_security_group_rules : [for rule_index, rules in main_object.ingress : merge(rules,{rule_id="${main_key}-INGRESS-R${rule_index}",main_key=main_key})]])
flatten([for main_key, main_object in var.ec2_security_group_rules : [for rule_index, rules in main_object.egress : merge(rules,{rule_id="${main_key}-EGRESS-R${rule_index}",main_key=main_key})]])

{for rule in flatten([for main_key, main_object in var.ec2_security_group_rules : [for rule_index, rules in main_object.ingress : merge(rules,{rule_id="${main_key}-INGRESS-R${rule_index}",main_key=main_key})]]) : rule.rule_id => rule }
{for rule in flatten([for main_key, main_object in var.ec2_security_group_rules : [for rule_index, rules in main_object.egress : merge(rules,{rule_id="${main_key}-EGRESS-R${rule_index}",main_key=main_key})]]) : rule.rule_id => rule}

*/
