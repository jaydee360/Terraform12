locals {
  vpc_name     = var.vpcName
  ssh_port     = var.sshPort
  feature_flag = var.featureFlag
  my_list      = var.myList
  my_map       = var.myMap
  my_tuple     = var.myTuple
  my_object    = var.myObject
  my_object_list = var.myObjectList
}

/*
  The input variables (defined in the variables.tf file), 
  The values for these variables are defined in the terraform.tfvars file.

  The values can be referenced using var. notation as follows:

  - var.vpcName
  - var.sshPort
  - var.featureFlag
  - var.myList
  - var.myMap
  - var.myTuple

  As shown above, the locals block can be used to create local variables that reference these input variables. For example:
  locals {
    my_local_var = var.vpcName
  }

*/

output "vpc_name" {
  value = var.vpcName  # This will output the value of vpcName
}

output "ssh_port" {
  value = var.sshPort  # This will output the value of sshPort
}

output "feature_flag" {
  value = var.featureFlag  # This will output the value of featureFlag
}

output "my_list" {
  value = var.myList  # This will output the value of myList
}

output "my_map" {
  value = var.myMap  # This will output the value of myMap
}

output "my_tuple" {
  value = var.myTuple  # This will output the value of myTuple
}

output "my_object" {
  value = var.myObject  # This will output the value of myObject
}
output "my_object_list" {
  value = var.myObjectList  # This will output the value of myObjectList
}
