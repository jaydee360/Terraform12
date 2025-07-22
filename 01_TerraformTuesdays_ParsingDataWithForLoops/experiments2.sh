# Instad of reading the JSON file to a local
# This time try the following approach:
# 1. Create a typed variable based on the JSON structure (variable.tf)
# 2. Supply the JSON data to the variable using a .tfvars file (config_data.tfvars.json)
#    (non-default var-file MUST be specified with -var-file option - e.g., "terraform apply -var-file=config_data.tfvars.json")

# 3. Use the variable in the Terraform configuration (main.tf)
# 4. Use a for loop to iterate over the data in the variable
# 5. Output the results to verify the data is parsed correctly


