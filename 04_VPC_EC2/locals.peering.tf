locals {

    vpc_peering_map = {
        for pcx_obj in var.vpc_peerings : "${pcx_obj.requester}__${pcx_obj.accepter}" => pcx_obj
    }

    vpc_connections = [
        for pcx_obj in var.vpc_peerings : 
        {
            a = pcx_obj.requester
            b = pcx_obj.accepter
            target_key = "${pcx_obj.requester}__${pcx_obj.accepter}"
        }
    ]

    vpc_summary = {
        for vpc_key, vpc_obj in var.vpc_config : vpc_key => {
            cidr = vpc_obj.vpc_cidr
        }
    }

    # vpc_peers_lookup = {
    #     for vpc_key, vpc_obj in local.vpc_summary : vpc_key => flatten([
    #         for conn in var.vpc_connections : 
    #         conn.a == vpc_key ? [conn.b] :
    #         conn.b == vpc_key ? [conn.a] : 
    #         []
    #     ])
    # }

    vpc_peers_lookup = {
        for vpc_key, vpc_obj in local.vpc_summary : vpc_key => flatten([
            for conn in local.vpc_connections : 
            conn.a == vpc_key ? [conn.b] :
            conn.b == vpc_key ? [conn.a] : 
            []
        ])
    }




}
