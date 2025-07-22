locals {
  # Load all of the data from json
  all_json_data = jsondecode(file("config_data.json"))

  # Load the first list of data directly
  list1_data = jsondecode(file("config_data.json")).List1

  # Load the first map indirectly
  map1_data = local.all_json_data.Map1
}

# Output the data fom List1 in the config_data variable, which is defined in the terraform.tfvars.json file
output "JDTEST" {
  value = var.config_data.List1
}