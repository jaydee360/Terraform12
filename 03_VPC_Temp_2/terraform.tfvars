aws_region = "us-east-1"
aws_profile = "terraform"

vpc_config = {
    "vpc_000" = {
        vpc_cidr = "10.0.0.0/16"
        enable_dns_support = true
        enable_dns_hostnames = true
        tags = {
            TAG = "This tag is from VPC_CONFIG > VPC_000"
        }
        igw = {
            create = true
            attach = true
            tags = {
                TAG = "This tag is from VPC_CONFIG > VPC_000 > IGW"
            }
        }
        subnets = {
            "public_subnet_000" = {
                subnet_cidr = "10.0.0.0/24"
                az = "a"
                create_nat_gw = true
                routing_policy = "public"
                override_routing_policy = false
                associate_routing_policy = true
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_000"
                }
            }
            "public_subnet_010" = {
                subnet_cidr = "10.0.1.0/24"
                az = "b"
                create_nat_gw = false
                routing_policy = "public"
                override_routing_policy = false
                associate_routing_policy = true
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_010"
                }
            }
            "public_subnet_020" = {
                subnet_cidr = "10.0.2.0/24"
                az = "c"
                create_nat_gw = false
                routing_policy = "public"
                override_routing_policy = false
                associate_routing_policy = true
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_020"
                }
            }
            "private_subnet_040" = {
                subnet_cidr = "10.0.4.0/24"
                az = "a"
                create_nat_gw = false
                routing_policy = "private_nat"
                override_routing_policy = false
                associate_routing_policy = true
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PRIVATE_SUBNET_040"
                }
            }
            "private_subnet_050" = {
                subnet_cidr = "10.0.5.0/24"
                az = "b"
                create_nat_gw = false
                routing_policy = "private_nat"
                override_routing_policy = false
                associate_routing_policy = true
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PRIVATE_SUBNET_050"
                }
            }
            "private_subnet_060" = {
                subnet_cidr = "10.0.6.0/24"
                az = "c"
                create_nat_gw = false
                routing_policy = "private_nat"
                override_routing_policy = false
                associate_routing_policy = true
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PRIVATE_SUBNET_060"
                }
            }
        }
    }
}

routing_policies = {
    "public" = {
        inject_igw = true
        inject_nat = false
        tags = {
            TAG = "This tag is from ROUTING_POLICIES > PUBLIC"
        }
    }
    "private_nat" = {
        inject_igw = false
        inject_nat = true
        tags = {
            TAG = "This tag is from ROUTING_POLICIES > PRIVATE_NAT"
        }
    }
}

route_table_config = {
    # TEMP PUBLIC SUBNET OVERRIDE RTs
    "vpc_000__public_subnet_010" = {
        inject_igw = false
        inject_nat = false
        tags = {
            TAG = "This tag is from ROUTE_TABLE_CONFIG > vpc_010__PUBLIC_SUBNET_000"
        }
    }
    "vpc_000__public_subnet_020" = {
        inject_igw = false
        inject_nat = false
        tags = {
            TAG = "This tag is from ROUTE_TABLE_CONFIG > vpc_020__PUBLIC_SUBNET_000"
        }
    }
}

ec2_config = {
    "web_01" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                description = "web_01 primary nic"
                vpc = "vpc_000"
                subnet = "public_subnet_000"
                security_groups = ["webserver_frontend", "SG-FAKE"]
                assign_eip = true
                tags = {
                    TAG = "This tag is from EC2_CONFIG > WEB_01 > NIC0"
                }
            }
        }
        tags = {
            Role = "frontend"
            TAG = "This tag is from EC2_CONFIG > WEB_01"
        }
    }
    "web_02" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                description = "web_02 primary nic"
                vpc = "vpc_000"
                subnet = "public_subnet_010"
                security_groups = ["webserver_frontend"]
                assign_eip = true
                tags = {
                    TAG = "This tag is from EC2_CONFIG > WEB_02 > NIC0"
                }
            }
            "nic1" = {
                description = "web_02 secondary nic"
                vpc = "vpc_000"
                subnet = "public_subnet_010"
                # private_ip_list_enabled = true
                # private_ip_list = ["10.0.1.20"]
                security_groups = ["webserver_backend"]
                tags = {
                    TAG = "This tag is from EC2_CONFIG > WEB_02 > NIC1"
                }
            }
        }
        tags = {
            Role = "frontend"
            TAG = "This tag is from EC2_CONFIG > WEB_02"
        }
    }
    "web_03" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                description = "web_03 primary nic"
                vpc = "vpc_000"
                subnet = "public_subnet_020"
                security_groups = ["webserver_frontend"]
                assign_eip = true
                tags = {
                    TAG = "This tag is from EC2_CONFIG > WEB_03 > NIC0"
                }
            }
            "nic1" = {
                description = "web_03 secondary nic"
                vpc = "vpc_000"
                subnet = "public_subnet_020"
                security_groups = ["webserver_backend"]
                tags = {
                    TAG = "This tag is from EC2_CONFIG > WEB_03 > NIC1"
                }
            }
        }
        tags = {
            Role = "frontend"
            TAG = "This tag is from EC2_CONFIG > WEB_03"
        }
    }
    "db_01" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        # user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                description = "db_01 primary nic"
                vpc = "vpc_000"
                subnet = "private_subnet_040"
                security_groups = ["db_server"]
                assign_eip = false
                tags = {
                    TAG = "This tag is from EC2_CONFIG > DB_01 > NIC0"
                }
            }
        }
        tags = {
            Role = "db"
            TAG = "This tag is from EC2_CONFIG > DB_01"
        }
    }
    "db_02" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        # user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                description = "db_02 primary nic"
                vpc = "vpc_000"
                subnet = "private_subnet_050"
                security_groups = ["db_server", "SG-FAKE"]
                assign_eip = false
                tags = {
                    TAG = "This tag is from EC2_CONFIG > DB_02 > NIC0"
                }
            }
        }
        tags = {
            Role = "db"
            TAG = "This tag is from EC2_CONFIG > DB_02"
        }
    }
    "db_03" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        # user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                description = "db_03 primary nic"
                vpc = "vpc_000"
                subnet = "private_subnet_060"
                security_groups = ["db_server"]
                assign_eip = false
                tags = {
                    TAG = "This tag is from EC2_CONFIG > DB_03 > NIC0"
                }
            }
        }
        tags = {
            Role = "db"
            TAG = "This tag is from EC2_CONFIG > DB_03"
        }
    }
}

prefix_list_config = {
    JD-HOME-LAB = {
        name           = "JD-HOME-LAB"
        address_family = "IPv4"
        max_entries    = 5
        entries = [
            { cidr = "212.56.102.213/32", description = "JD Home Lab Internet IP" }
        ]
        tags = {
            TAG = "This tag is from PREFIX_LIST_CONFIG > JD-HOME-LAB"   
        }
    }
}

security_group_config = {
    "webserver_frontend" = {
        vpc_id      = "vpc_000"
        description = "webserver_frontend SG with inline rules"
        ingress_ref = "WEB-FRONTEND-IN"
        ingress = [
            {
                description = "80-IN"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                prefix_list_id = "JD-HOME-LAB"
                cidr_ipv4 =  "0.0.0.0/0"
                tags = {
                    TAG = "INLINE: This tag is from SECURITY_GROUP_CONFIG >  webserver_frontend > INGRESS > 80-IN"
                }
            },
            {
                description = "443-IN"
                from_port = 443
                to_port = 443
                protocol = "tcp"
                prefix_list_id = "JD-HOME-LAB"
                cidr_ipv4 =  "0.0.0.0/0"
                tags = {
                    TAG = "INLINE: This tag is from SECURITY_GROUP_CONFIG >  webserver_frontend > INGRESS > 443-IN"
                }
            }
        ]
        egress_ref = "ANY-OUT"
        egress = [
            {
                description = "ANY-ANY-OUT"
                protocol = "-1"
                cidr_ipv4 =  "0.0.0.0/0"
                tags = {
                    TAG = "INLINE: This tag is from SECURITY_GROUP_CONFIG >  WEB_01__NIC0_WEB > EGRESS > ANY-ANY-OUT"
                }
            }
        ]
        tags = {
            TAG = "This tag is SECURITY_GROUP_CONFIG > webserver_frontend"
        }
    }
    "webserver_backend" = {
        vpc_id      = "vpc_000"
        description = "webserver_backend SG with shared rules"
        ingress_ref = "WEB-BACKEND-IN"
        tags = {
            TAG = "This tag is SECURITY_GROUP_CONFIG > webserver_frontend"
        }
    }
    "db_server" = {
        vpc_id      = "vpc_000"
        description = "db_server SG with shared rules"
        ingress_ref = "DB-IN"
        egress_ref  = "ANY-OUT"
        tags = {
            TAG = "This tag is SECURITY_GROUP_CONFIG > db_server"
        }
    }
}

shared_security_group_rules = {
    "WEB-FRONTEND-IN" = {
        ingress = [
            {
                description = "SHARED-80-IN"
                from_port = 80
                to_port = 80
                prefix_list_id = "JD-HOME-LAB"
                protocol = "tcp"
                tags = {
                    TAG = "This tag is from SHARED_SECURITY_GROUP_RULES > WEB-FRONTEND-IN > INGRESS > SHARED-80-IN"
                }
            },
            {
                description = "SHARED-443-IN"
                from_port = 443
                to_port = 443
                prefix_list_id = "JD-HOME-LAB"
                protocol = "tcp"
                tags = {
                    TAG = "This tag is from SHARED_SECURITY_GROUP_RULES > WEB-FRONTEND-IN > INGRESS > SHARED-443-IN"
                }
            }
        ]
        egress = []
    }
    "ANY-OUT" = {
        ingress = []
        egress = [
            {
                description = "SHARED-ANY-OUT"
                protocol = "-1"
                cidr_ipv4 = "0.0.0.0/0"
                tags = {
                    TAG = "This tag is from SHARED_SECURITY_GROUP_RULES > ANY-OUT > EGRESS > SHARED-ANY-OUT"
                }
            }
        ]
    }
    "WEB-BACKEND-IN" = {
        ingress = [
            {
                description = "SHARED-8080-IN"
                from_port = 8080
                to_port = 8080
                protocol = "tcp"
                # prefix_list_id = "JD-HOME-LAB"
                referenced_security_group_id = "db_server"
                cidr_ipv4 =  "10.0.0.0/16"
                tags = {
                    TAG = "This tag is from SHARED_SECURITY_GROUP_RULES > WEB-BACKEND-IN > INGRESS > SHARED-8080-IN"
                }
            },
            {
                description = "SHARED-4567-IN"
                from_port = 4567
                to_port = 4567
                protocol = "tcp"
                referenced_security_group_id = "db_server"
                cidr_ipv4 =  "10.0.0.0/16"
                tags = {
                    TAG = "This tag is from SHARED_SECURITY_GROUP_RULES > WEB-BACKEND-IN > INGRESS > SHARED-4567-IN"
                }
            }
        ]
        egress = []
    }
    "DB-IN" = {
        ingress = [
            {
                description = "SHARED-1433-IN"
                from_port = 1433
                to_port = 1433
                protocol = "tcp"
                cidr_ipv4 =  "10.0.0.0/16"
                tags = {
                    TAG = "This tag is from SHARED_SECURITY_GROUP_RULES > DB-IN > INGRESS > SHARED-1433-IN"
                }
            },
        ]
        egress = []
    }
}

