aws_region = "us-east-1"
aws_profile = "terraform"

vpc_config = {
    "vpc_000" = {
        vpc_cidr = "10.0.0.0/16"
        enable_dns_support = true
        enable_dns_hostnames = true
        tags = {
            VPC_TAG = "yes"
        }
        igw = {
            create = true
            attach = true
            tags = {
                IGW_TAG = "yes"
            }
        }
        subnets = {
            "public_subnet_000" = {
                subnet_cidr = "10.0.0.0/24"
                az = "a"
                create_nat_gw = false
                routing_policy = "public"
                associate_routing_policy = true
                override_routing_policy = false
                tags = {
                    type = "public"
                    SUBNET_TAG = "yes"
                }
            }
            "public_subnet_010" = {
                subnet_cidr = "10.0.1.0/24"
                az = "b"
                create_nat_gw = false
                routing_policy = "public"
                associate_routing_policy = true
                override_routing_policy = false
                tags = {
                    type = "public"
                    SUBNET_TAG = "yes"
                }
            }
            "public_subnet_020" = {
                subnet_cidr = "10.0.2.0/24"
                az = "c"
                create_nat_gw = false
                routing_policy = "public"
                associate_routing_policy = true
                override_routing_policy = false
                tags = {
                    type = "public"
                    SUBNET_TAG = "yes"
                }
            }
            "private_subnet_040" = {
                subnet_cidr = "10.0.4.0/24"
                az = "a"
                create_nat_gw = false
                routing_policy = "private_nat"
                associate_routing_policy = true
                override_routing_policy = false
                tags = {
                    type = "private"
                    SUBNET_TAG = "yes"
                }
            }
            "private_subnet_050" = {
                subnet_cidr = "10.0.5.0/24"
                az = "b"
                create_nat_gw = false
                routing_policy = "private_nat"
                associate_routing_policy = true
                override_routing_policy = false
                tags = {
                    type = "private"
                    SUBNET_TAG = "yes"
                }
            }
            "private_subnet_060" = {
                subnet_cidr = "10.0.6.0/24"
                az = "c"
                create_nat_gw = false
                routing_policy = "private_nat"
                associate_routing_policy = true
                override_routing_policy = false
                tags = {
                    type = "private"
                    SUBNET_TAG = "yes"
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
        }
    }
    "private_nat" = {
        inject_igw = false
        inject_nat = true
        tags = {
        }
    }
}

route_table_config = {
    # TEMP PUBLIC SUBNET RTs
    "vpc_000__public_subnet_000" = {
        inject_igw = false
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
}

ec2_config_v2 = {
    "web_01" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "A4L"
        user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                description = "jd test web_01"
                vpc = "vpc_000"
                subnet = "public_subnet_000"
                security_groups = ["web_01__nic0_web", "SG-FAKE"]
                assign_eip = true
                tags = {
                    NIC0_TAGS = "yes"
                }
            }
            # "nic1" = {
            #     description = "jd test web_01"
            #     vpc = "vpc-lab-dev-000"
            #     subnet = "snet-lab-dev-000-public-a"
            #     private_ips_count = 1
            #     security_groups = ["SG-2-WEB", "SG-FAKE"]
            #     tags = {
            #         NIC1_TAGS = "yes"
            #     }
            # }
        }
        tags = {
            Role = "frontend"
            INST_TAGS = "yes"
        }
    }
    # "web_02" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "jd test web_02"
    #             vpc = "vpc-lab-dev-000"
    #             subnet = "snet-lab-dev-000-public-b"
    #             security_groups = ["SG-2-WEB", "SG-FAKE"]
    #             assign_eip = true
    #             tags = {
    #                 NIC0_TAGS = "yes"
    #             }
    #         }
    #         "nic1" = {
    #             description = "jd test web_02"
    #             vpc = "vpc-lab-dev-000"
    #             subnet = "snet-lab-dev-000-public-b"
    #             private_ip_list_enabled = true
    #             private_ip_list = ["10.0.1.20"]
    #             security_groups = ["SG-2-WEB", "SG-FAKE"]
    #             tags = {
    #                 NIC1_TAGS = "yes"
    #             }
    #         }
    #     }
    #     tags = {
    #         Role = "frontend"
    #         INST_TAGS = "yes"
    #     }
    # }
    # "web_03" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "jd test web_03"
    #             vpc = "vpc-lab-dev-000"
    #             subnet = "snet-lab-dev-000-public-c"
    #             security_groups = ["SG-2-WEB", "SG-FAKE"]
    #         }
    #         "nic1" = {
    #             description = "jd test web_03"
    #             vpc = "vpc-lab-dev-000"
    #             subnet = "snet-lab-dev-000-public-c"
    #             security_groups = ["SG-2-WEB", "SG-FAKE"]
    #         }
    #     }
    #     tags = {
    #         Role = "frontend"
    #     }
    # }
    # "web_04" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "jd test web_03"
    #             vpc = "vpc-lab-dev-000"
    #             subnet = "snet-lab-dev-000-public-c"
    #             security_groups = ["SG-2-WEB", "SG-FAKE"]
    #         }
    #     }
    #     tags = {
    #         Role = "frontend"
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
            PL_TAGS = "yes"            
        }
    }
    # PREFIX-LIST-TEST = {
    #     name           = "PREFIX-LIST-TEST"
    #     address_family = "IPv4"
    #     max_entries    = 5
    #     entries = [
    #         { cidr = "192.168.100.0/24", description = "Partner A" },
    #         { cidr = "192.168.101.0/24", description = "Partner B" }
    #     ]
    #     tags = {
    #         PL_TAGS = "yes"            
    #     }
    # }
}

security_group_config = {
    # "web_01__nic0" = {
    #     vpc_id      = "vpc-lab-dev-000"
    #     description = "SG-2-WEB with inline rules"
    #     # ingress_ref = "DB-RULES"
    #     ingress = [
    #         {
    #             description = "80-IN"
    #             from_port = 80
    #             to_port = 80
    #             protocol = "tcp"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "0.0.0.0/0" 
    #         },
    #         {
    #             description = "443-IN"
    #             from_port = 443
    #             to_port = 443
    #             protocol = "tcp"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "0.0.0.0/0"
    #         },
    #         {
    #             description = "22-IN"
    #             from_port = 22
    #             to_port = 22
    #             protocol = "tcp"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "0.0.0.0/0" 
    #         },
    #         {
    #             description = "3389-IN"
    #             from_port = 3389
    #             to_port = 3389
    #             protocol = "tcp"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "0.0.0.0/0"
    #         },
    #         {
    #             description = "DB-IN-TEST"
    #             from_port = 8080
    #             to_port = 8080
    #             protocol = "tcp"
    #             # referenced_security_group_id = "SG-1-DB"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "0.0.0.0/0"
    #         }
    #     ]
    #     # egress_ref = "DB-RULES"
    #     egress = [
    #         {
    #             description = "ANY-ANY-OUT"
    #             protocol = "-1"
    #             cidr_ipv4 =  "0.0.0.0/0" 
    #         }
    #     ]
    #     tags = {
    #         SG_TAGS = "yes"
    #     }
    # }
    "web_01__nic0_web" = {
        vpc_id      = "vpc_000"
        description = "SG-2-WEB with inline rules"
        ingress_ref = "WEB-TRAFFIC-IN"
        ingress = [
            {
                description = "80-IN"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                prefix_list_id = "JD-HOME-LAB"
                cidr_ipv4 =  "0.0.0.0/0" 
            },
            {
                description = "443-IN"
                from_port = 443
                to_port = 443
                protocol = "tcp"
                prefix_list_id = "JD-HOME-LAB"
                cidr_ipv4 =  "0.0.0.0/0"
            }
        ]
        egress_ref = "ANY-OUT"
        egress = [
            {
                description = "ANY-ANY-OUT"
                protocol = "-1"
                cidr_ipv4 =  "0.0.0.0/0" 
            }
        ]
        tags = {
            SG_TAGS = "yes"
        }
    }
    # "SG-1-DB" = {
    #     vpc_id      = "vpc-lab-dev-000"
    #     description = "SG-1-DB referencing DB-RULES"
    #     ingress_ref = "DB-RULES"
    #     ingress = [
    #         {
    #             description = "1433-IN"
    #             from_port = 1433
    #             to_port = 1433
    #             protocol = "tcp"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         },
    #         {
    #             description = "1433-IN"
    #             from_port = 1433
    #             to_port = 1433
    #             protocol = "tcp"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         },
    #         {
    #             description = "3389-IN"
    #             from_port = 3389
    #             to_port = 3389
    #             protocol = "tcp"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         }
    #     ]
    #     # egress_ref = "DB-RULES"
    #     egress = [
    #         {
    #             description = "ANY-ANY-OUT"
    #             protocol = "-1"
    #             referenced_security_group_id = "SG-2-WEB"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "0.0.0.0/0" 
    #         }
    #     ]
    #     tags = {
    #         SG_TAGS = "yes"
    #     }
    # }
    # "SG-1-APP" = {
    #    vpc_id      = "vpc-lab-dev-001"
    #    description = "SG-1-APP currently inert"
    #    # ingress_ref = "APP-RULES"
    #    # ingress = []
    #    # egress = []
    # }
}

shared_security_group_rules = {
    "WEB-TRAFFIC-IN" = {
        ingress = [
            {
                # cidr_ipv4 = "value"
                description = "SHARED-80-IN"
                from_port = 80
                to_port = 80
                prefix_list_id = "JD-HOME-LAB"
                protocol = "tcp"
                # referenced_security_group_id = ""
            },
            {
                # cidr_ipv4 = "value"
                description = "SHARED-443-IN"
                from_port = 443
                to_port = 443
                prefix_list_id = "JD-HOME-LAB"
                protocol = "tcp"
                # referenced_security_group_id = ""
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
            }
        ]
    }
    # "DB-RULES" = {
    #     ingress = [
    #         {
    #             description = "123-IN-NEW"
    #             from_port = 123
    #             to_port = 123
    #             protocol = "tcp"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         },
    #         {
    #             description = "456-IN"
    #             from_port = 456
    #             to_port = 456
    #             protocol = "tcp"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         },
    #         {
    #             description = "789-IN"
    #             from_port = 789
    #             to_port = 789
    #             protocol = "tcp"
    #             referenced_security_group_id = "SG-2-WEB"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         },
    #         {
    #             description = "789-IN"
    #             from_port = 789
    #             to_port = 789
    #             protocol = "tcp"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         }
    #     ]
    #     egress = [
    #         {
    #             description = "987-OUT"
    #             from_port = 987
    #             to_port = 987
    #             protocol = "tcp"
    #             referenced_security_group_id = "SG-2-WEB"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         },
    #         {
    #             description = "654-IN"
    #             from_port = 654
    #             to_port = 654
    #             protocol = "tcp"
    #             prefix_list_id = "JD-HOME-LAB"
    #             cidr_ipv4 =  "10.0.0.0/16" 
    #         }
    #     ]
    # }
    # "APP-RULES" = {
    #     ingress = []
    #     egress = []
    # }
}

