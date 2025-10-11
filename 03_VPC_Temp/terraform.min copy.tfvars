vpc_config = {
    "vpc-lab-dev-000" = {
        vpc_cidr = "10.0.0.0/16"
        enable_dns_support   = true
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
            "snet-lab-dev-000-public-a" = {
                az          = "a"
                subnet_cidr = "10.0.0.0/24"
                tags = {
                    "type" = "public"
                    "SUBNET_TAG" = "yes"
                }
                has_route_table = false
                has_nat_gw = false
            }
            "snet-lab-dev-000-public-b" = {
                az          = "b"
                subnet_cidr = "10.0.1.0/24"
                tags = {
                    "type" = "public"
                    "SUBNET_TAG" = "yes"
                }
                has_route_table = false
                has_nat_gw = false
            }
            # "snet-lab-dev-000-public-c" = {
            #     az          = "c"
            #     subnet_cidr = "10.0.2.0/24"
            #     tags = {
            #         "type" = "public"
            #         "SUBNET_TAG" = "yes"
            #     }
            #     has_route_table = false
            #     has_nat_gw = false
            # }
            # "snet-lab-dev-000-public-d" = {
            #     az          = "d"
            #     subnet_cidr = "10.0.3.0/24"
            #     tags = {
            #         "type" = "public"
            #         "SUBNET_TAG" = "yes"
            #     }
            #     has_route_table = false
            #     has_nat_gw = false
            # }
            "snet-lab-dev-000-private-a" = {
                az          = "a"
                subnet_cidr = "10.0.4.0/24"
                tags = {
                    "type" = "private"
                    "SUBNET_TAG" = "yes"
                }
                has_route_table = false
                has_nat_gw = false
            }
            "snet-lab-dev-000-private-b" = {
                az          = "b"
                subnet_cidr = "10.0.5.0/24"
                tags = {
                    "type" = "private"
                    "SUBNET_TAG" = "yes"
                }
                has_route_table = false
                has_nat_gw = false
            }
            "snet-lab-dev-000-private-c" = {
                az          = "c"
                subnet_cidr = "10.0.6.0/24"
                tags = {
                    "type" = "private"
                    "SUBNET_TAG" = "yes"
                }
                has_route_table = false
                has_nat_gw = false
            }
            # "snet-lab-dev-000-private-d" = {
            #     az          = "d"
            #     subnet_cidr = "10.0.7.0/24"
            #     tags = {
            #         "type" = "private"
            #         "SUBNET_TAG" = "yes"
            #     }
            #     has_route_table = false
            #     has_nat_gw = false
            # }
        }
    }
/*     "vpc-lab-dev-100" = {
        vpc_cidr = "10.1.0.0/16"
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
            "snet-lab-dev-100-public-a" = {
                az          = "a"
                subnet_cidr = "10.1.0.0/24"
                tags = {
                    type = "public"
                    VPC_TAG = "yes"
                }
                has_route_table = true
                has_nat_gw = true
            }
            "snet-lab-dev-100-public-b" = {
                az          = "b"
                subnet_cidr = "10.1.1.0/24"
                tags = {
                    type = "public"
                    VPC_TAG = "yes"
                }
                has_route_table = true
            }
            "snet-lab-dev-100-public-c" = {
                az          = "c"
                subnet_cidr = "10.1.2.0/24"
                tags = {
                    type = "public"
                    VPC_TAG = "yes"
                }
                has_route_table = true
            }
            "snet-lab-dev-100-private-a" = {
                az          = "a"
                subnet_cidr = "10.1.4.0/24"
                tags = {
                    type = "private"
                    VPC_TAG = "yes"
                }
                has_route_table = true
            }
            "snet-lab-dev-100-private-b" = {
                az          = "b"
                subnet_cidr = "10.1.5.0/24"
                tags = {
                    type = "private"
                    VPC_TAG = "yes"
                }
                has_route_table = true
            }
            "snet-lab-dev-100-private-c" = {
                az          = "c"
                subnet_cidr = "10.1.6.0/24"
                tags = {
                    type = "private"
                    VPC_TAG = "yes"
                }
                has_route_table = true
            }
            "snet-lab-dev-100-private-d" = {
                az          = "d"
                subnet_cidr = "10.1.7.0/24"
                tags = {
                    type = "private"
                    VPC_TAG = "yes"
                }
                has_route_table = true
            }
        }
    } */
}

route_table_config = {
    # "vpc-lab-dev-000__snet-lab-dev-000-public-a" = {
    #     inject_igw = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-000__snet-lab-dev-000-public-b" = {
    #     inject_igw = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-000__snet-lab-dev-000-public-c" = {
    #     inject_igw = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    #  "vpc-lab-dev-000__snet-lab-dev-000-public-d" = {
    #     inject_igw = false
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-000__snet-lab-dev-000-private-a" = {
    #     inject_nat = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-000__snet-lab-dev-000-private-b" = {
    #     inject_nat = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-000__snet-lab-dev-000-private-c" = {
    #     inject_nat = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-100__snet-lab-dev-100-public-a" = {
    #     inject_igw = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-100__snet-lab-dev-100-public-b" = {
    #     inject_igw = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-100__snet-lab-dev-100-public-c" = {
    #     inject_igw = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-100__snet-lab-dev-100-private-a" = {
    #     inject_nat = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-100__snet-lab-dev-100-private-b" = {
    #     inject_nat = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-100__snet-lab-dev-100-private-c" = {
    #     inject_nat = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
    # "vpc-lab-dev-100__snet-lab-dev-100-private-d" = {
    #     inject_nat = true
    #     tags = {
    #         RT_TAG = "yes"
    #     }
    # }
}

/* ec2_config = {
    "web_02" = {
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        vpc = "vpc-lab-dev-000"
        subnet = "snet-lab-dev-000-public-a"
        key_name = "A4L"
        associate_public_ip_address = true
        user_data_script = "server-script.sh"
        vpc_security_group_ids = ["SG-2-WEB", "SG-FAKE"]
        tags = {
            Role = "frontend"
        }
    }
} */

ec2_config_v2 = {
    # "web_01" = {
    #     ami = "ami-0150ccaf51ab55a51"
    #     instance_type = "t3.micro"
    #     key_name = "A4L"
    #     user_data_script = "server-script.sh"
    #     network_interfaces = {
    #         "nic0" = {
    #             description = "jd test web_01"
    #             vpc = "vpc-lab-dev-000"
    #             subnet = "snet-lab-dev-000-public-a"
    #             security_groups = ["SG-2-WEB", "SG-FAKE"]
    #             assign_eip = true
    #             tags = {
    #                 NIC0_TAGS = "yes"
    #             }
    #         }
    #         "nic1" = {
    #             description = "jd test web_01"
    #             vpc = "vpc-lab-dev-000"
    #             subnet = "snet-lab-dev-000-public-a"
    #             private_ips_count = 1
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
    # JD-HOME-LAB = {
    #     name           = "JD-HOME-LAB"
    #     address_family = "IPv4"
    #     max_entries    = 5
    #     entries = [
    #         { cidr = "212.56.102.213/32", description = "JD Home Lab Internet IP" }
    #     ]
    #     tags = {
    #         PL_TAGS = "yes"            
    #     }
    # }
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
/*     "SG-1-DB" = {
        vpc_id      = "vpc-lab-dev-000"
        description = "SG-1-DB referencing DB-RULES"
        ingress_ref = "DB-RULES"
        ingress = [
            {
                description = "1433-IN"
                from_port = 1433
                to_port = 1433
                protocol = "tcp"
                cidr_ipv4 =  "10.0.0.0/16" 
            },
            {
                description = "1433-IN"
                from_port = 1433
                to_port = 1433
                protocol = "tcp"
                cidr_ipv4 =  "10.0.0.0/16" 
            },
            {
                description = "3389-IN"
                from_port = 3389
                to_port = 3389
                protocol = "tcp"
                cidr_ipv4 =  "10.0.0.0/16" 
            }
        ]
        # egress_ref = "DB-RULES"
        egress = [
            {
                description = "ANY-ANY-OUT"
                protocol = "-1"
                referenced_security_group_id = "SG-2-WEB"
                prefix_list_id = "JD-HOME-LAB"
                cidr_ipv4 =  "0.0.0.0/0" 
            }
        ]
        tags = {
            SG_TAGS = "yes"
        }
    } */
    # "SG-2-WEB" = {
    #     vpc_id      = "vpc-lab-dev-000"
    #     description = "SG-2-WEB with inline rules"
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
    #             cidr_ipv4 =  "0.0.0.0/0" 
    #         },
    #         {
    #             description = "3389-IN"
    #             from_port = 3389
    #             to_port = 3389
    #             protocol = "tcp"
    #             cidr_ipv4 =  "0.0.0.0/0"
    #         },
    #         {
    #             description = "DB-IN-TEST"
    #             from_port = 8080
    #             to_port = 8080
    #             protocol = "tcp"
    #             referenced_security_group_id = "SG-1-DB"
    #             cidr_ipv4 =  "0.0.0.0/0"
    #         }
    #     ]
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
/*     "SG-1-APP" = {
        vpc_id      = "vpc-lab-dev-001"
        description = "SG-1-APP currently inert"
        # ingress_ref = "APP-RULES"
        # ingress = []
        # egress = []
    } */
}

shared_security_group_rules = {
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

