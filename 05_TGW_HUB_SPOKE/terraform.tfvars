tgw_config = {
    tgw_hub = {
        account = "aws25_dev"
        region = "us-east-2"
        amazon_side_asn = 64512
        description = "dev tgw"
        default_route_table_association = "disable"
        auto_accept_shared_attachments = "enable"
        route_tables = {
            spoke_rt = {
                is_default = false
                associations = ["vpc-core", "vpc-app", "vpc-db", "vpc-analytics", "vpc-edge"]
                propagations = ["vpc-core", "vpc-app", "vpc-db", "vpc-analytics", "vpc-edge"]
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
}

vpc_config = {
    vpc-core = {
        region = "us-east-2"
        vpc_cidr = "10.0.0.0/16"
        subnets = {
            vpc-core-tgw-subnet-a = {
                subnet_cidr    = "10.0.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_hub"
            }
            vpc-core-tgw-subnet-b = {
                subnet_cidr    = "10.0.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_hub"
            }
            vpc-core-tgw-subnet-c = {
                subnet_cidr    = "10.0.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_hub"
            }
            vpc-core-app-subnet-a = {
                subnet_cidr    = "10.0.64.0/24"
                az             = "a"
                routing_policy = "app_subnet"
            }
            vpc-core-app-subnet-b = {
                subnet_cidr    = "10.0.65.0/24"
                az             = "b"
                routing_policy = "app_subnet"
            }
            vpc-core-app-subnet-c = {
                subnet_cidr    = "10.0.66.0/24"
                az             = "c"
                routing_policy = "app_subnet"
            }
            vpc-core-data-subnet-a = {
                subnet_cidr    = "10.0.128.0/24"
                az             = "a"
                routing_policy = "data_subnet"
            }
            vpc-core-data-subnet-b = {
                subnet_cidr    = "10.0.129.0/24"
                az             = "b"
                routing_policy = "data_subnet"
            }
            vpc-core-data-subnet-c = {
                subnet_cidr    = "10.0.130.0/24"
                az             = "c"
                routing_policy = "data_subnet"
            }
        }
    }
    vpc-app = {
        region = "us-east-2"
        vpc_cidr = "10.1.0.0/16"
        subnets = {
            vpc-app-tgw-subnet-a = {
                subnet_cidr    = "10.1.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_hub"
            }
            vpc-app-tgw-subnet-b = {
                subnet_cidr    = "10.1.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_hub"
            }
            vpc-app-tgw-subnet-c = {
                subnet_cidr    = "10.1.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_hub"
            }
            vpc-app-app-subnet-a = {
                subnet_cidr    = "10.1.64.0/24"
                az             = "a"
                routing_policy = "app_subnet"
            }
            vpc-app-app-subnet-b = {
                subnet_cidr    = "10.1.65.0/24"
                az             = "b"
                routing_policy = "app_subnet"
            }
            vpc-app-app-subnet-c = {
                subnet_cidr    = "10.1.66.0/24"
                az             = "c"
                routing_policy = "app_subnet"
            }
            vpc-app-data-subnet-a = {
                subnet_cidr    = "10.1.128.0/24"
                az             = "a"
                routing_policy = "data_subnet"
            }
            vpc-app-data-subnet-b = {
                subnet_cidr    = "10.1.129.0/24"
                az             = "b"
                routing_policy = "data_subnet"
            }
            vpc-app-data-subnet-c = {
                subnet_cidr    = "10.1.130.0/24"
                az             = "c"
                routing_policy = "data_subnet"
            }
        }
    }
    vpc-db = {
        region = "us-east-2"
        vpc_cidr = "10.2.0.0/16"
        subnets = {
            vpc-db-tgw-subnet-a = {
                subnet_cidr    = "10.2.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_hub"
            }
            vpc-db-tgw-subnet-b = {
                subnet_cidr    = "10.2.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_hub"
            }
            vpc-db-tgw-subnet-c = {
                subnet_cidr    = "10.2.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_hub"
            }
            vpc-db-app-subnet-a = {
                subnet_cidr    = "10.2.64.0/24"
                az             = "a"
                routing_policy = "app_subnet"
            }
            vpc-db-app-subnet-b = {
                subnet_cidr    = "10.2.65.0/24"
                az             = "b"
                routing_policy = "app_subnet"
            }
            vpc-db-app-subnet-c = {
                subnet_cidr    = "10.2.66.0/24"
                az             = "c"
                routing_policy = "app_subnet"
            }
            vpc-db-data-subnet-a = {
                subnet_cidr    = "10.2.128.0/24"
                az             = "a"
                routing_policy = "data_subnet"
            }
            vpc-db-data-subnet-b = {
                subnet_cidr    = "10.2.129.0/24"
                az             = "b"
                routing_policy = "data_subnet"
            }
            vpc-db-data-subnet-c = {
                subnet_cidr    = "10.2.130.0/24"
                az             = "c"
                routing_policy = "data_subnet"
            }
        }
    }
    vpc-analytics = {
        region = "us-east-2"
        vpc_cidr = "10.3.0.0/16"
        subnets = {
            vpc-analytics-tgw-subnet-a = {
                subnet_cidr    = "10.3.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_hub"
            }
            vpc-analytics-tgw-subnet-b = {
                subnet_cidr    = "10.3.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_hub"
            }
            vpc-analytics-tgw-subnet-c = {
                subnet_cidr    = "10.3.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_hub"
            }
            vpc-analytics-app-subnet-a = {
                subnet_cidr    = "10.3.64.0/24"
                az             = "a"
                routing_policy = "app_subnet"
            }
            vpc-analytics-app-subnet-b = {
                subnet_cidr    = "10.3.65.0/24"
                az             = "b"
                routing_policy = "app_subnet"
            }
            vpc-analytics-app-subnet-c = {
                subnet_cidr    = "10.3.66.0/24"
                az             = "c"
                routing_policy = "app_subnet"
            }
            vpc-analytics-data-subnet-a = {
                subnet_cidr    = "10.3.128.0/24"
                az             = "a"
                routing_policy = "data_subnet"
            }
            vpc-analytics-data-subnet-b = {
                subnet_cidr    = "10.3.129.0/24"
                az             = "b"
                routing_policy = "data_subnet"
            }
            vpc-analytics-data-subnet-c = {
                subnet_cidr    = "10.3.130.0/24"
                az             = "c"
                routing_policy = "data_subnet"
            }
        }
    }
    vpc-edge = {
        region = "us-east-2"
        vpc_cidr = "10.4.0.0/16"
        subnets = {
            vpc-edge-tgw-subnet-a = {
                subnet_cidr    = "10.4.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_hub"
            }
            vpc-edge-tgw-subnet-b = {
                subnet_cidr    = "10.4.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_hub"
            }
            vpc-edge-tgw-subnet-c = {
                subnet_cidr    = "10.4.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_hub"
            }
            vpc-edge-app-subnet-a = {
                subnet_cidr    = "10.4.64.0/24"
                az             = "a"
                routing_policy = "app_subnet"
            }
            vpc-edge-app-subnet-b = {
                subnet_cidr    = "10.4.65.0/24"
                az             = "b"
                routing_policy = "app_subnet"
            }
            vpc-edge-app-subnet-c = {
                subnet_cidr    = "10.4.66.0/24"
                az             = "c"
                routing_policy = "app_subnet"
            }
            vpc-edge-data-subnet-a = {
                subnet_cidr    = "10.4.128.0/24"
                az             = "a"
                routing_policy = "data_subnet"
            }
            vpc-edge-data-subnet-b = {
                subnet_cidr    = "10.4.129.0/24"
                az             = "b"
                routing_policy = "data_subnet"
            }
            vpc-edge-data-subnet-c = {
                subnet_cidr    = "10.4.130.0/24"
                az             = "c"
                routing_policy = "data_subnet"
            }
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
    private_tgw = {
        inject_tgw = true
    }
    app_subnet = {        
        inject_tgw = true
    }
    data_subnet = {        
        inject_tgw = true
    }
    tgw_attach_hub = {
        tgw_key = "tgw_hub"
    }
}

