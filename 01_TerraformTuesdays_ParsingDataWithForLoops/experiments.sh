# Using the locals defined as follows:

locals {
  # Load all of the data from json
  all_json_data = jsondecode(file("config_data.json"))
}

# ALL DATA
# --------
# Show all the JSON data loaded into the local variable
local.all_json_data

# SPECIFIC ELEMENT OF DATA
# ------------------------
# Show a specific element (List1) from the JSON data
local.all_json_data.List1

# Try to access the first element of the Local variable by index
# NOTE: This will not work as `local.all_json_data` is not a list.
local.all_json_data[0]

# Understand the type of data in the local variable
# NOTE: `local.all_json_data` is an object, not a list.
type(local.all_json_data)

/*
object({
  Key: string,
    List1: tuple([
        string,
        string,
        string,
        ...
*/

# We can access the elements of 'all_json_data' using the keys defined in the JSON structure.

# EXAMINE List1
# -------------
# List1 is a list of strings, as defined in the JSON.
# Given that List1 is a list, we can access its elements by index or by key lookup.
# Access the first element of List1
local.all_json_data.List1[0]
# Access the second element of List1
local.all_json_data.List1[1]

# EXAMINE Map1
# ------------
# Map1 is a map (or dictionary) with string keys and string values.
# We can access its elements by key lookup.
# Access the value of MapKey1 in Map1
local.all_json_data.Map1["MapKey1"] # This returns "MapValue1"
# Access the value of MapKey2 in Map1
local.all_json_data.Map1["MapKey2"] # This returns "MapValue2"

# EXAMINE Map2
# ------------
# Map2 is a map that contains another map (SubMap1) and a string (MapKey1).
# We can access its elements by key lookup.

# Access all the data in Map2
local.all_json_data.Map2

# Returns the entire Map2 object
/* ---EXAMPLE OUTPUT---
{
  "SubMap1" = {
    "SubKey1" = "SubValue1"
    "SubList1" = [
      "SubListValue1",
      "SubListValue2",
      "SubListValue3",
    ]
  }
}
--- END EXAMPLE OUTPUT --- */

# Access the data in SubMap1
# SubMap1 is a map within Map2, so we can access it by its key
local.all_json_data.Map2["SubMap1"] # This returns a map, which we can further explore.

# Access the value of SubKey1 in SubMap1
local.all_json_data.Map2["SubMap1"]["SubKey1"] # This returns "SubValue1"
# Access the SubList1 in SubMap1
local.all_json_data.Map2["SubMap1"]["SubList1"] # This returns the entire SubList1
# Access the first element of SubList1
local.all_json_data.Map2["SubMap1"]["SubList1"][0] # This returns "SubListValue1"

