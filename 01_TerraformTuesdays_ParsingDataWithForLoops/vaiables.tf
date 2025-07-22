variable "config_data" {
  type = object({
    Key    = string

    List1 = list(string)

    Map1 = map(string)

    Map2 = object({
      SubMap1 = object({
        SubList1 = list(string)
        SubKey1  = string
      })
    })

    List3 = list(object({
      List3SubKey1 = optional(string)
      List3SubKey2 = optional(string)
      List3SubKey3 = optional(string)
      Food         = string
    }))
  })
}