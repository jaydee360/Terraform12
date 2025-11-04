tgw_config = {
    tgw_dev_hub_use_2 = {
        account = "aws25_dev"
        region = "us-east-2"
        amazon_side_asn = 64512
        description = "dev tgw"
        default_route_table_association = "disable"
        auto_accept_shared_attachments = "enable"
        route_tables = {
            spoke_rt = {
                is_default = false
                associations = ["vpc_spoke_use_2_000", "vpc_spoke_use_2_100"]
                propagations = ["vpc_spoke_use_2_000", "vpc_spoke_use_2_100"]
            }
            inspection_rt = {
                is_default = false
                associations = []
                propagations = []
            }
        }
        tags = {
            type = "public"
            source = "tgw"
        }
    }
    # tgw-prod-hub-us-east-2 = {
        #     account = "aws25_prod"
        #     region = "us-west-1"
        #     amazon_side_asn = 64512
        #     description = "dev tgw twat"
        #     auto_accept_shared_attachments = "enable"
        #     tags = {
        #         type = "public"
        #         TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_000"
        #     }
    # }
}

vpc_config = {
    "vpc_spoke_use_2_000" = {
        region = "us-east-2"
        vpc_cidr = "10.0.0.0/16"
        enable_dns_support = true
        enable_dns_hostnames = true
        create_igw = false
        subnets = {
        # public subnets
            # public_000a = {
            #     subnet_cidr = "10.0.0.0/24"
            #     az = "a"
            #     routing_policy  = "public"
            #     create_natgw = true
            # }
            # public_010b = {
            #     subnet_cidr = "10.0.1.0/24"
            #     az = "b"
            #     routing_policy  = "public"
            #     create_natgw = false
            # }
            # public_020c = {
            #     subnet_cidr = "10.0.2.0/24"
            #     az = "c"
            #     routing_policy  = "public"
            #     create_natgw = false
            # }
        # private nat subnets
            # private_040a = {
            #     subnet_cidr = "10.0.4.0/24"
            #     az = "a"
            #     routing_policy  = "private_nat"
            #     create_natgw = false
            # }
            # private_050b = {
            #     subnet_cidr = "10.0.5.0/24"
            #     az = "b"
            #     routing_policy  = "private_nat"
            #     create_natgw = false
            # }
            # private_060c = {
            #     subnet_cidr = "10.0.6.0/24"
            #     az = "c"
            #     routing_policy  = "private_nat"
            #     create_natgw = false
            # }
        # tgw attachment subnets
            tgw_att_0128a = {
                subnet_cidr = "10.0.128.0/28"
                az = "a"
                routing_policy  = "tgw_attach_dev_hub"
            }
            tgw_att_0128b = {
                subnet_cidr = "10.0.128.16/28"
                az = "b"
                routing_policy  = "tgw_attach_dev_hub"
            }
            tgw_att_0128c = {
                subnet_cidr = "10.0.128.32/28"
                az = "c"
                routing_policy  = "tgw_attach_dev_hub"
            }
        }
        tags = {
            source = "vpc"
        }
    }
    "vpc_spoke_use_2_100" = {
        region = "us-east-2"
        vpc_cidr = "10.1.0.0/16"
        enable_dns_support = true
        enable_dns_hostnames = true
        create_igw = false
        subnets = {
        # public subnets
            # public_000a = {
            #     subnet_cidr = "10.0.0.0/24"
            #     az = "a"
            #     routing_policy  = "public"
            #     create_natgw = true
            # }
            # public_010b = {
            #     subnet_cidr = "10.0.1.0/24"
            #     az = "b"
            #     routing_policy  = "public"
            #     create_natgw = false
            # }
            # public_020c = {
            #     subnet_cidr = "10.0.2.0/24"
            #     az = "c"
            #     routing_policy  = "public"
            #     create_natgw = false
            # }
        # private nat subnets
            # private_040a = {
            #     subnet_cidr = "10.0.4.0/24"
            #     az = "a"
            #     routing_policy  = "private_nat"
            #     create_natgw = false
            # }
            # private_050b = {
            #     subnet_cidr = "10.0.5.0/24"
            #     az = "b"
            #     routing_policy  = "private_nat"
            #     create_natgw = false
            # }
            # private_060c = {
            #     subnet_cidr = "10.0.6.0/24"
            #     az = "c"
            #     routing_policy  = "private_nat"
            #     create_natgw = false
            # }
        # tgw attachment subnets
            tgw_att_1128a = {
                subnet_cidr = "10.1.128.0/28"
                az = "a"
                routing_policy  = "tgw_attach_dev_hub"
            }
            tgw_att_1128b = {
                subnet_cidr = "10.1.128.16/28"
                az = "b"
                routing_policy  = "tgw_attach_dev_hub"
            }
            tgw_att_1128c = {
                subnet_cidr = "10.1.128.32/28"
                az = "c"
                routing_policy  = "tgw_attach_dev_hub"
            }
        }
        tags = {
            source = "vpc"
        }
    }
}


routing_policies = {
    public = {
        inject_igw = true
    }
    private_nat = {
        inject_nat = true
    }
    tgw_attach_dev_hub = {
        tgw_key = "tgw_dev_hub_use_2"
    }
}