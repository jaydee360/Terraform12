aws_region = "us-east-1"
aws_profile = "terraform"

vpc_config = {
    vpc_000 = {
        vpc_cidr = "10.0.0.0/16"
        enable_dns_support = true
        enable_dns_hostnames = true
        create_igw = true
        tags = {
            TAG = "This tag is from VPC_CONFIG > VPC_000"
        }
        subnets = {
            "public_subnet_000" = {
                subnet_cidr = "10.0.0.0/24"
                az = "a"
                create_natgw = true
                routing_policy = "public"
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_000"
                }
            }
            "public_subnet_010" = {
                subnet_cidr = "10.0.1.0/24"
                az = "b"
                create_natgw = true
                routing_policy = "public"
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_010"
                }
            }
            "public_subnet_020" = {
                subnet_cidr = "10.0.2.0/24"
                az = "c"
                create_natgw = true
                routing_policy = "public"
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_020"
                }
            }
            "private_subnet_040" = {
                subnet_cidr = "10.0.4.0/24"
                az = "a"
                create_natgw = false
                routing_policy = "private_nat"
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PRIVATE_SUBNET_040"
                }
            }
            "private_subnet_050" = {
                subnet_cidr = "10.0.5.0/24"
                az = "b"
                create_natgw = false
                #routing_policy = "private_nat"
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PRIVATE_SUBNET_050"
                }
            }
            "private_subnet_060" = {
                subnet_cidr = "10.0.6.0/24"
                az = "c"
                create_natgw = false
                #routing_policy = "private_nat"
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PRIVATE_SUBNET_060"
                }
            }
        }
    }
    vpc_100 = {
        vpc_cidr = "10.1.0.0/16"
        enable_dns_support = true
        enable_dns_hostnames = true
        create_igw = false
        tags = {
            TAG = "This tag is from VPC_CONFIG > VPC_100"
        }
        subnets = {
            "public_subnet_100" = {
                subnet_cidr = "10.1.0.0/24"
                az = "a"
                create_natgw = true
                routing_policy = "public"
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_100 > SUBNET > PUBLIC_SUBNET_100"
                }
            }
            "public_subnet_110" = {
                subnet_cidr = "10.1.1.0/24"
                az = "b"
                create_natgw = false
                routing_policy = "public"
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_100 > SUBNET > PUBLIC_SUBNET_110"
                }
            }
            "public_subnet_120" = {
                subnet_cidr = "10.1.2.0/24"
                az = "c"
                create_natgw = false
                routing_policy = "public"
                tags = {
                    type = "public"
                    TAG = "This tag is from VPC_CONFIG > VPC_100 > SUBNET > PUBLIC_SUBNET_120"
                }
            }
            "private_subnet_140" = {
                subnet_cidr = "10.1.4.0/24"
                az = "a"
                create_natgw = false
                routing_policy = "private_nat"
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_100 > SUBNET > PRIVATE_SUBNET_140"
                }
            }
            "private_subnet_150" = {
                subnet_cidr = "10.1.5.0/24"
                az = "b"
                create_natgw = false
                routing_policy = "private_nat"
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_100 > SUBNET > PRIVATE_SUBNET_150"
                }
            }
            "private_subnet_160" = {
                subnet_cidr = "10.1.6.0/24"
                az = "c"
                create_natgw = false
                routing_policy = "private_nat"
                tags = {
                    type = "private"
                    TAG = "This tag is from VPC_CONFIG > VPC_100 > SUBNET > PRIVATE_SUBNET_160"
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

ec2_profiles = {
    webserver = {
        # most of the paramters for this server type are now set using ec2_profile templates
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                routing_policy = "public"
                security_groups = ["webserver_frontend"]
                assign_eip = true
            }
        }
        tags = {
            Role = "frontend"
            Source  = "webserver_profile"
        }
    }
    database = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        network_interfaces = {
            "nic0" = {
                routing_policy = "private-nat"
                security_groups = ["database_backend"]
                assign_eip = false
            }
        }     
    }
}

ec2_instances = {
    web_00 = {
        ec2_profile = "webserver"
        network_interfaces = {
            "nic0" = {
                vpc = "vpc_000"
                az = "a"
            }
            # "nic1" = {
            #     routing_policy = "public"
            #     security_groups = ["webserver_frontend"]
            #     assign_eip = false
            #     vpc = "vpc_000"
            #     az = "a"
            # }
        }
    }
    web_01 = {
        ec2_profile = "webserver"
        network_interfaces = {
            "nic0" = {
                vpc = "vpc_000"
                az = "b"
            }
        }
    }
    web_02 = {
        ec2_profile = "webserver"
        network_interfaces = {
            "nic0" = {
                vpc = "vpc_000"
                az = "c"
            }
            "nic1" = {
                routing_policy = "public"
                security_groups = ["webserver_frontend"]
                assign_eip = false
                vpc = "vpc_000"
                az = "c"
            }
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
    # "web_03" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "web_03 primary nic"
    #             vpc = "vpc_000"
    #             subnet = "public_subnet_020"
    #             security_groups = ["webserver_frontend"]
    #             assign_eip = true
    #             tags = {
    #                 TAG = "This tag is from EC2_CONFIG > WEB_03 > NIC0"
    #             }
    #         }
    #         "nic1" = {
    #             description = "web_03 secondary nic"
    #             vpc = "vpc_000"
    #             subnet = "public_subnet_020"
    #             security_groups = ["webserver_backend"]
    #             tags = {
    #                 TAG = "This tag is from EC2_CONFIG > WEB_03 > NIC1"
    #             }
    #         }
    #     }
    #     tags = {
    #         Role = "frontend"
    #         TAG = "This tag is from EC2_CONFIG > WEB_03"
    #     }
    # }
    # "db_01" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     # user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "db_01 primary nic"
    #             vpc = "vpc_000"
    #             subnet = "private_subnet_040"
    #             security_groups = ["db_server"]
    #             assign_eip = false
    #             tags = {
    #                 TAG = "This tag is from EC2_CONFIG > DB_01 > NIC0"
    #             }
    #         }
    #     }
    #     tags = {
    #         Role = "db"
    #         TAG = "This tag is from EC2_CONFIG > DB_01"
    #     }
    # }
    # "db_02" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     # user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "db_02 primary nic"
    #             vpc = "vpc_000"
    #             subnet = "private_subnet_050"
    #             security_groups = ["db_server", "SG-FAKE"]
    #             assign_eip = false
    #             tags = {
    #                 TAG = "This tag is from EC2_CONFIG > DB_02 > NIC0"
    #             }
    #         }
    #     }
    #     tags = {
    #         Role = "db"
    #         TAG = "This tag is from EC2_CONFIG > DB_02"
    #     }
    # }
    # "db_03" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     # user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "db_03 primary nic"
    #             vpc = "vpc_000"
    #             subnet = "private_subnet_060"
    #             security_groups = ["db_server"]
    #             assign_eip = false
    #             tags = {
    #                 TAG = "This tag is from EC2_CONFIG > DB_03 > NIC0"
    #             }
    #         }
    #     }
    #     tags = {
    #         Role = "db"
    #         TAG = "This tag is from EC2_CONFIG > DB_03"
    #     }
    # }
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

security_groups = {
    "webserver_frontend" = {
        vpc_id      = "vpc_000"
        description = "webserver_frontend SG"
        ingress_ref = ["WEB_FRONTEND_IN", "ADMIN_IN"]
        egress_ref = ["ANY_OUT"]
        tags = {
            TAG = "SECURITY_GROUPS > WEBSERVER_FRONTEND"
        }
    }
    "database" = {
        vpc_id      = "vpc_000"
        description = "database SG"
        ingress_ref = ["DB_MYSQL_INTERNAL", "DB_MYSQL_ADMIN", "DB_POSTGRES_INTERNAL"]
        egress_ref = ["ANY_OUT"]
        tags = {
            TAG = "SECURITY_GROUPS > DATABASE"
        }
    }
}


security_group_rule_sets = {
    "WEB_FRONTEND_IN" = [
        {
            description = "SHARED-80-IN"
            from_port = 80
            to_port = 80
            cidr_ipv4 =  "0.0.0.0/0"
            ip_protocol = "tcp"
            tags = {
                TAG = "SECURITY_GROUP_RULES > WEB-FRONTEND-IN > SHARED-80-IN"
            }
        },
        {
            description = "SHARED-443-IN"
            from_port = 443
            to_port = 443
            cidr_ipv4 =  "0.0.0.0/0"
            ip_protocol = "tcp"
            tags = {
                TAG = "SECURITY_GROUP_RULES > WEB-FRONTEND-IN > SHARED-443-IN"
            }
        }
    ]
    "ADMIN_IN" = [
        {
            description = "SHARED-SSH-IN"
            from_port = 22
            to_port = 22
            #referenced_security_group_id = "JDTEST"
            prefix_list_id = "JD-HOME-LAB"
            ip_protocol = "tcp"
            tags = {
                TAG = "SECURITY_GROUP_RULES > ADMIN-IN > SHARED-SSH-IN"
            }
        },
        {
            description = "SHARED-RDP-IN"
            from_port = 3389
            to_port = 3389
            #referenced_security_group_id = "JDTEST"
            prefix_list_id = "JD-HOME-LAB"
            ip_protocol = "tcp"
            tags = {
                TAG = "SECURITY_GROUP_RULES > ADMIN-IN > SHARED-RDP-IN"
            }
        }
    ]
    "ANY_OUT" = [
        {
            description = "ANY-OUT"
            ip_protocol = "-1"
            cidr_ipv4 = "0.0.0.0/0"
            tags = {
                TAG = "SECURITY_GROUP_RULES > ANY-OUT > SHARED-ANY-OUT"
            }
        }
    ]
    DB_MYSQL_INTERNAL = [
        {
            description                  = "Allow MySQL from webserver_frontend SG"
            referenced_security_group_id = "webserver_frontend"
            ip_protocol                     = "tcp"
            from_port                    = 3306
            to_port                      = 3306
        }
    ]
    DB_MYSQL_ADMIN = [
        {
            description  = "Allow MySQL from admin IP range"
            cidr_ipv4    = "203.0.113.0/24"
            ip_protocol     = "tcp"
            from_port    = 3306
            to_port      = 3306
        }
    ]
    DB_POSTGRES_INTERNAL = [
        {
            description                  = "Allow PostgreSQL from app SG"
            referenced_security_group_id = "webserver_frontend"
            ip_protocol                     = "tcp"
            from_port                    = 5432
            to_port                      = 5432
        }
    ]
}