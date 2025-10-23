locals {

    vpc_peering_map = {
        for pcx_obj in var.vpc_peerings : "${pcx_obj.requester}__${pcx_obj.accepter}" => pcx_obj
    }

    vpc_peering_connections_list = [
        for pcx_obj in var.vpc_peerings : 
        {
            a = pcx_obj.requester
            b = pcx_obj.accepter
            target_type = "peering"
            target_key = "${pcx_obj.requester}__${pcx_obj.accepter}"
        }
    ]

    vpc_connections_list = flatten([
        local.vpc_peering_connections_list
    ])

    vpc_summary_map = {
        for vpc_key, vpc_obj in var.vpc_config : vpc_key => {
            cidr = vpc_obj.vpc_cidr
        }
    }

    vpc_peer_lookup_map = {
        for vpc_key, vpc_obj in local.vpc_summary_map : vpc_key => flatten([
            for conn in local.vpc_connections_list : 
            conn.a == vpc_key ? [{
                peer_vpc = conn.b
                target_type = conn.target_type
                target_key = conn.target_key
            }] :
            conn.b == vpc_key ? [{
                peer_vpc = conn.a 
                target_type = conn.target_type
                target_key = conn.target_key
            }] : 
            []
        ])
    }
}
