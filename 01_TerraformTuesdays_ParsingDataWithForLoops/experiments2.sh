# Instad of reading the JSON file to a local
# This time try the following approach:
# 1. Create a typed variable based on the JSON structure (variable.tf)
# 2. Supply the JSON data to the variable using a .tfvars file (config_data.tfvars.json)
#    (non-default var-file MUST be specified with -var-file option - e.g., "terraform apply -var-file=config_data.tfvars.json")

# 3. Use the variable in the Terraform configuration (main.tf)
# 4. Use a for loop to iterate over the data in the variable
# 5. Output the results to verify the data is parsed correctly


{
    for food in distinct([for item in local.all_json_data.List3 : item.Food]) :
    food => [
      for item in local.all_json_data.List3 : lookup(item,[for k in keys(item) : k if startswith(k, "List3SubKey")][0],null)
      if item.Food == food
    ]
}


# How about a for loop on a list?
[ for i in local.all_json_data.List1 : upper(i) ]

# What about transposing keys and values?
{ for key, val in local.map1_data : val => key }

[ for k, v in local.map1_data : "${v}-${k}" ]

# How about we get a list for only Tacos?
[ for i in local.all_json_data.List3 : i if i.Food == "Taco"]
