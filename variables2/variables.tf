variable "vpcName" {
    type = string
}

variable "sshPort" {
    type = number
}

variable "featureFlag" {
    type = bool
}

variable "myList" {
    type = list(string)
}

variable "myMap" {
    type = map
}

variable "myTuple" {
    type = tuple([
        string, 
        number, 
        string, 
        bool
    ])
}

variable "myObject" {
    type = object({
      name = string,
      age  = number,
      active = bool,
      tags = list(string),
      attributes = map(string)
    })
}

variable "myObjectList" {
    type = list(object({
      name = string,
      location = optional(string, "bollocks"),
      description = optional(string, "No description provided")
    }))
}
