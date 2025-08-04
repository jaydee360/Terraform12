locals {
    enriched_subnets = flatten(
        [for vpc_key, vpc_obj in var.vpc_config : 
            [for subnet_idx, subnets in vpc_obj.subnets : 
                merge(subnets,{"sid"="${vpc_key}-${subnet_idx}","vpc"="${vpc_key}"})
            ]
        ]
    )
}

locals {
    subnet_map = {
        for flat_subnet in local.enriched_subnets : 
        "${flat_subnet.sid}" => flat_subnet
    }
}