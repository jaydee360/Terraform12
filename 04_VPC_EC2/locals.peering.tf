locals {
    vpc_summary = {
        for vpc_key, vpc_obj in var.vpc_config : vpc_key => {
            cidr = vpc_obj.vpc_cidr
        }
    }
}
