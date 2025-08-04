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

locals {
    igw_list = [
        for vpc_key, vpc in var.vpc_config : 
        merge(vpc.igw,{"vpc_key"="${vpc_key}"}) if vpc.igw !=null 
    ]
}

locals {
    igw_map = {
        for igw_key, igw in local.igw_list :
        "${igw.vpc_key}" => igw
    }
}

locals {
    igw_create_map = {
        for igw_key, igw in local.igw_list :
        "${igw.vpc_key}" => igw if igw.create
    }
}

locals {
    igw_attach_map = {
        for igw_key, igw in local.igw_list :
        "${igw.vpc_key}" => igw if igw.attach && igw.create
    }
}