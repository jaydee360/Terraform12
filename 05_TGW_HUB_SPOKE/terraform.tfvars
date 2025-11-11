fw_policy_config = {
  test-policy = {
    region = "us-east-2"
    stateless_default_actions = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]
  }
}

fw_config = {
  test-fw = {
    region = "us-east-2"
    vpc_key = "vpc-inspection"
    subnet_keys = ["vpc-inspection-fw-subnet-a", "vpc-inspection-fw-subnet-b", "vpc-inspection-fw-subnet-c"]
    policy_key = "test-policy"
  }
}


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
                associations = ["vpc-core", "vpc-app", "vpc-db"]
                propagations = []
                routes = [{
                  cidr_block = "0.0.0.0/0"
                  target_key = "vpc-inspection"
                }]
            }
            edge_rt = {
                is_default = false
                associations = ["vpc-edge"]
                propagations = []
                routes = [{
                  cidr_block = "10.4.0.0/14"
                  target_key = "vpc-inspection"
                }]
            }
            inspection_rt = {
                is_default = false
                associations = ["vpc-inspection"]
                propagations = ["vpc-core", "vpc-app", "vpc-db"]
                routes = [{
                  cidr_block = "0.0.0.0/0"
                  target_key = "vpc-edge"
                }]
            }
        }
        tags = {
            source = "tgw"
        }
    }
}

vpc_config = {
    vpc-edge = {
        region = "us-east-2"
        vpc_cidr = "10.0.0.0/16"
        create_igw = true
        subnets = {
            vpc-edge-tgw-subnet-a = {
                subnet_cidr    = "10.0.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-edge-tgw-subnet-b = {
                subnet_cidr    = "10.0.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-edge-tgw-subnet-c = {
                subnet_cidr    = "10.0.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-edge-public-subnet-a = {
                subnet_cidr    = "10.0.4.0/24"
                az             = "a"
                routing_policy = "edge_public_subnets"
                create_natgw   = true
            }
            vpc-edge-public-subnet-b = {
                subnet_cidr    = "10.0.5.0/24"
                az             = "b"
                routing_policy = "edge_public_subnets"
                create_natgw   = true
            }
            vpc-edge-public-subnet-c = {
                subnet_cidr    = "10.0.6.0/24"
                az             = "c"
                routing_policy = "edge_public_subnets"
                create_natgw   = true
            }
        }
    }
    vpc-inspection = {
        region = "us-east-2"
        vpc_cidr = "10.1.0.0/16"
        subnets = {
            vpc-inspection-tgw-subnet-a = {
                subnet_cidr    = "10.1.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_tgw_hub_inspection"
            }
            vpc-inspection-tgw-subnet-b = {
                subnet_cidr    = "10.1.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_tgw_hub_inspection"
            }
            vpc-inspection-tgw-subnet-c = {
                subnet_cidr    = "10.1.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_tgw_hub_inspection"
            }
            vpc-inspection-fw-subnet-a = {
                subnet_cidr    = "10.1.4.0/24"
                az             = "a"
                routing_policy = "inspection_fw_subnets"
            }
            vpc-inspection-fw-subnet-b = {
                subnet_cidr    = "10.1.5.0/24"
                az             = "b"
                routing_policy = "inspection_fw_subnets"
            }
            vpc-inspection-fw-subnet-c = {
                subnet_cidr    = "10.1.6.0/24"
                az             = "c"
                routing_policy = "inspection_fw_subnets"
            }
        }
    }
    vpc-core = {
        region = "us-east-2"
        vpc_cidr = "10.4.0.0/16"
        subnets = {
            vpc-core-tgw-subnet-a = {
                subnet_cidr    = "10.4.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-core-tgw-subnet-b = {
                subnet_cidr    = "10.4.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-core-tgw-subnet-c = {
                subnet_cidr    = "10.4.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-core-app-subnet-a = {
                # "RT:SN:vpc-core__vpc-core-app-subnet-a"
                subnet_cidr    = "10.4.4.0/24"
                az             = "a"
                routing_policy = "spoke_app_subnets"
            }
            vpc-core-app-subnet-b = {
                # "RT:SN:vpc-core__vpc-core-app-subnet-b"
                subnet_cidr    = "10.4.5.0/24"
                az             = "b"
                routing_policy = "spoke_app_subnets"
            }
            vpc-core-app-subnet-c = {
                # "RT:SN:vpc-core__vpc-core-app-subnet-c"
                subnet_cidr    = "10.4.6.0/24"
                az             = "c"
                routing_policy = "spoke_app_subnets"
            }
            vpc-core-data-subnet-a = {
                subnet_cidr    = "10.4.8.0/24"
                az             = "a"
                routing_policy = "spoke_data_subnets"
            }
            vpc-core-data-subnet-b = {
                subnet_cidr    = "10.4.9.0/24"
                az             = "b"
                routing_policy = "spoke_data_subnets"
            }
            vpc-core-data-subnet-c = {
                subnet_cidr    = "10.4.10.0/24"
                az             = "c"
                routing_policy = "spoke_data_subnets"
            }
        }
    }
    vpc-app = {
        region = "us-east-2"
        vpc_cidr = "10.5.0.0/16"
        subnets = {
            vpc-app-tgw-subnet-a = {
                subnet_cidr    = "10.5.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-app-tgw-subnet-b = {
                subnet_cidr    = "10.5.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-app-tgw-subnet-c = {
                subnet_cidr    = "10.5.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-app-app-subnet-a = {
                subnet_cidr    = "10.5.4.0/24"
                az             = "a"
                routing_policy = "spoke_app_subnets"
            }
            vpc-app-app-subnet-b = {
                subnet_cidr    = "10.5.5.0/24"
                az             = "b"
                routing_policy = "spoke_app_subnets"
            }
            vpc-app-app-subnet-c = {
                subnet_cidr    = "10.5.6.0/24"
                az             = "c"
                routing_policy = "spoke_app_subnets"
            }
            vpc-app-data-subnet-a = {
                subnet_cidr    = "10.5.8.0/24"
                az             = "a"
                routing_policy = "spoke_data_subnets"
            }
            vpc-app-data-subnet-b = {
                subnet_cidr    = "10.5.9.0/24"
                az             = "b"
                routing_policy = "spoke_data_subnets"
            }
            vpc-app-data-subnet-c = {
                subnet_cidr    = "10.5.10.0/24"
                az             = "c"
                routing_policy = "spoke_data_subnets"
            }
        }
    }
    vpc-db = {
        region = "us-east-2"
        vpc_cidr = "10.6.0.0/16"
        subnets = {
            vpc-db-tgw-subnet-a = {
                subnet_cidr    = "10.6.0.0/28"
                az             = "a"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-db-tgw-subnet-b = {
                subnet_cidr    = "10.6.0.16/28"
                az             = "b"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-db-tgw-subnet-c = {
                subnet_cidr    = "10.6.0.32/28"
                az             = "c"
                routing_policy = "tgw_attach_tgw_hub"
            }
            vpc-db-app-subnet-a = {
                subnet_cidr    = "10.6.4.0/24"
                az             = "a"
                routing_policy = "spoke_app_subnets"
            }
            vpc-db-app-subnet-b = {
                subnet_cidr    = "10.6.5.0/24"
                az             = "b"
                routing_policy = "spoke_app_subnets"
            }
            vpc-db-app-subnet-c = {
                subnet_cidr    = "10.6.6.0/24"
                az             = "c"
                routing_policy = "spoke_app_subnets"
            }
            vpc-db-data-subnet-a = {
                subnet_cidr    = "10.6.8.0/24"
                az             = "a"
                routing_policy = "spoke_data_subnets"
            }
            vpc-db-data-subnet-b = {
                subnet_cidr    = "10.6.9.0/24"
                az             = "b"
                routing_policy = "spoke_data_subnets"
            }
            vpc-db-data-subnet-c = {
                subnet_cidr    = "10.6.10.0/24"
                az             = "c"
                routing_policy = "spoke_data_subnets"
            }
        }
    }
}

routing_policies = {
    edge_public_subnets = {
        inject_igw = true
        inject_tgw = true
    }
    spoke_app_subnets = {        
        routes = [{
          cidr_block = "0.0.0.0/0"
          target_key = "tgw_hub"
          target_type = "tgw"
        }]
    }
    spoke_data_subnets = {        
        routes = [{
          cidr_block = "0.0.0.0/0"
          target_key = "tgw_hub"
          target_type = "tgw"
        }]
    }
    inspection_fw_subnets = {        
        routes = [{
          cidr_block = "0.0.0.0/0"
          target_key = "tgw_hub"
          target_type = "tgw"
        }]
    }
    tgw_attach_tgw_hub = {
        tgw_key = "tgw_hub"
        inject_nat = true
    }
    tgw_attach_tgw_hub_inspection = {
        tgw_key = "tgw_hub"
        tgw_app_mode = "enable"
        fw_key = "test-fw"
        inject_fw = true
    }
}

