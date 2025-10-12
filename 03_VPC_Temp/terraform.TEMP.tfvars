aws_region = "us-east-1"
aws_profile = "terraform"

vpc_config = {
    "vpc_01" = {
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
            "public_subnet_01" = {
                subnet_cidr = "10.0.0.0/24"
                az = "a"
                route_table = {
                    associate = true
                    rt_suffix = "test"
                }
                associate_route_table = true
                create_nat_gw = true
                tags = {
                    type = "public"
                    SUBNET_TAG = "yes"
                }
            }
            "public_subnet_02" = {
                subnet_cidr = "10.0.1.0/24"
                az = "b"
                route_table = {
                    associate = true
                    rt_suffix = "test"
                }
                associate_route_table = true
                create_nat_gw = true
                tags = {
                    type = "public"
                    SUBNET_TAG = "yes"
                }
            }
            "public_subnet_03" = {
                subnet_cidr = "10.0.2.0/24"
                az = "c"
                route_table = {
                    associate = true
                    rt_suffix = "test"
                }
                associate_route_table = true
                create_nat_gw = true
                tags = {
                    type = "public"
                    SUBNET_TAG = "yes"
                }
            }
            "private_subnet_01" = {
                subnet_cidr = "10.0.4.0/24"
                az = "a"
                route_table = {
                    associate = true
                    rt_suffix = "test"
                }
                associate_route_table = true
                create_nat_gw = false
                tags = {
                    type = "private"
                    SUBNET_TAG = "yes"
                }
            }
            "private_subnet_02" = {
                subnet_cidr = "10.0.5.0/24"
                az = "b"
                route_table = {
                    associate = true
                    rt_suffix = "test"
                }
                associate_route_table = true
                create_nat_gw = false
                tags = {
                    type = "private"
                    SUBNET_TAG = "yes"
                }
            }
            "private_subnet_03" = {
                subnet_cidr = "10.0.6.0/24"
                az = "c"
                route_table = {
                    associate = true
                    rt_suffix = "test"
                }
                associate_route_table = true
                create_nat_gw = false
                tags = {
                    type = "private"
                    SUBNET_TAG = "yes"
                }
            }
        }
    }
}

# vpc_config = {
#     "vpc-lab-dev-000" = {
#         vpc_cidr = "10.0.0.0/16"
#         enable_dns_support   = true
#         enable_dns_hostnames = true
#         tags = {
#             VPC_TAG = "yes"
#         }
#         igw = {
#             create = true
#             attach = true
#             tags = {
#                 IGW_TAG = "yes"
#             }
#         }
#         subnets = {
#             # PUBLIC SUBNETS
#             "snet-lab-dev-000-public-a" = {
#                 az          = "a"
#                 subnet_cidr = "10.0.0.0/24"
#                 tags = {
#                     "type" = "public"
#                     "SUBNET_TAG" = "yes"
#                 }
#                 associate_route_table = true
#                 create_nat_gw = false
#             }
#             "snet-lab-dev-000-public-b" = {
#                 az          = "b"
#                 subnet_cidr = "10.0.1.0/24"
#                 tags = {
#                     "type" = "public"
#                     "SUBNET_TAG" = "yes"
#                 }
#                 associate_route_table = true
#                 create_nat_gw = true
#             }
#             "snet-lab-dev-000-public-c" = {
#                 az          = "c"
#                 subnet_cidr = "10.0.2.0/24"
#                 tags = {
#                     "type" = "public"
#                     "SUBNET_TAG" = "yes"
#                 }
#                 associate_route_table = true
#                 create_nat_gw = false
#             }
#             # PRIVATE SUBNETS
#             "snet-lab-dev-000-private-a" = {
#                 az          = "a"
#                 subnet_cidr = "10.0.4.0/24"
#                 tags = {
#                     "type" = "private"
#                     "SUBNET_TAG" = "yes"
#                 }
#                 associate_route_table = false
#                 create_nat_gw = false
#             }
#             "snet-lab-dev-000-private-b" = {
#                 az          = "b"
#                 subnet_cidr = "10.0.5.0/24"
#                 tags = {
#                     "type" = "private"
#                     "SUBNET_TAG" = "yes"
#                 }
#                 associate_route_table = false
#                 create_nat_gw = false
#             }
#             "snet-lab-dev-000-private-c" = {
#                 az          = "c"
#                 subnet_cidr = "10.0.6.0/24"
#                 tags = {
#                     "type" = "private"
#                     "SUBNET_TAG" = "yes"
#                 }
#                 associate_route_table = false
#                 create_nat_gw = false
#             }
#         }
#     }
#     # "vpc-lab-dev-100" = {
#     #     vpc_cidr = "10.1.0.0/16"
#     #     tags = {
#     #         VPC_TAG = "yes"
#     #     }
#     #     igw = {
#     #         create = true
#     #         attach = true
#     #         tags = {
#     #             IGW_TAG = "yes"
#     #         }
#     #     }
#     #     subnets = {
#     #         # PUBLIC SUBNETS
#     #             # "snet-lab-dev-100-public-a" = {
#     #             #     az          = "a"
#     #             #     subnet_cidr = "10.1.0.0/24"
#     #             #     tags = {
#     #             #         type = "public"
#     #             #         VPC_TAG = "yes"
#     #             #     }
#     #             #     associate_route_table = false
#     #             #     create_nat_gw = false
#     #             # }
#     #             # "snet-lab-dev-100-public-b" = {
#     #             #     az          = "b"
#     #             #     subnet_cidr = "10.1.1.0/24"
#     #             #     tags = {
#     #             #         type = "public"
#     #             #         VPC_TAG = "yes"
#     #             #     }
#     #             #     associate_route_table = false
#     #             #     create_nat_gw = false
#     #             # }
#     #             # "snet-lab-dev-100-public-c" = {
#     #             #     az          = "c"
#     #             #     subnet_cidr = "10.1.2.0/24"
#     #             #     tags = {
#     #             #         type = "public"
#     #             #         VPC_TAG = "yes"
#     #             #     }
#     #             #     associate_route_table = false
#     #             #     create_nat_gw = false
#     #             # }
#     #         # PRIVATE SUBNETS
#     #             # "snet-lab-dev-100-private-a" = {
#     #             #     az          = "a"
#     #             #     subnet_cidr = "10.1.4.0/24"
#     #             #     tags = {
#     #             #         type = "private"
#     #             #         VPC_TAG = "yes"
#     #             #     }
#     #             #     associate_route_table = false
#     #             #     create_nat_gw = false
#     #             # }
#     #             # "snet-lab-dev-100-private-b" = {
#     #             #     az          = "b"
#     #             #     subnet_cidr = "10.1.5.0/24"
#     #             #     tags = {
#     #             #         type = "private"
#     #             #         VPC_TAG = "yes"
#     #             #     }
#     #             #     associate_route_table = false
#     #             #     create_nat_gw = false
#     #             # }
#     #             # "snet-lab-dev-100-private-c" = {
#     #             #     az          = "c"
#     #             #     subnet_cidr = "10.1.6.0/24"
#     #             #     tags = {
#     #             #         type = "private"
#     #             #         VPC_TAG = "yes"
#     #             #     }
#     #             #     associate_route_table = false
#     #             #     create_nat_gw = false
#     #             # }
#     #             # "snet-lab-dev-100-private-d" = {
#     #             #     az          = "d"
#     #             #     subnet_cidr = "10.1.7.0/24"
#     #             #     tags = {
#     #             #         type = "private"
#     #             #         VPC_TAG = "yes"
#     #             #     }
#     #             #     associate_route_table = false
#     #             #     create_nat_gw = false
#     #             # }
#     #     }
#     # }
# }

route_table_config = {
    # TEMP PUBLIC SUBNET RTs
    "vpc_01__public_subnet_01" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
    "vpc_01__public_subnet_01__ALT" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "ALTERNATE"
        }
    }
    "vpc_01__public_subnet_02" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
    "vpc_01__public_subnet_02__ALT" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "ALTERNATE"
        }
    }
    "vpc_01__public_subnet_03" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
    "vpc_01__public_subnet_03__ALT" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "ALTERNATE"
        }
    }
    "vpc_01__public_subnet_04" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
    "vpc_01__public_subnet_04__ALT" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "ALTERNATE"
        }
    }
    "vpc_01__private_subnet_01" = {
        inject_igw = false
        inject_nat = true
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
    "vpc_01__private_subnet_01__ALT" = {
        inject_igw = false
        inject_nat = true
        tags = {
            RT_TAG = "yes"
            role = "ALTERNATE"
        }
    }
    "vpc_01__private_subnet_02" = {
        inject_igw = false
        inject_nat = true
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
    "vpc_01__private_subnet_02__ALT" = {
        inject_igw = false
        inject_nat = true
        tags = {
            RT_TAG = "yes"
            role = "ALTERNATE"
        }
    }
    "vpc_01__private_subnet_03" = {
        inject_igw = false
        inject_nat = true
        tags = {
            RT_TAG = "yes"
            role = "PRIMARY"
        }
    }
    "vpc_01__private_subnet_03__ALT" = {
        inject_igw = false
        inject_nat = true
        tags = {
            RT_TAG = "yes"
            role = "ALTERNATE"
        }
    }
    "SomethingTotalNonsense" = {
        inject_igw = true
        inject_nat = false
        tags = {
            RT_TAG = "yes"
            role = "RANDOM"
        }
    }
}

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
    #             security_groups = ["web_01__nic0", "SG-FAKE"]
    #             assign_eip = true
    #             tags = {
    #                 NIC0_TAGS = "yes"
    #             }
    #         }
    #         # "nic1" = {
    #         #     description = "jd test web_01"
    #         #     vpc = "vpc-lab-dev-000"
    #         #     subnet = "snet-lab-dev-000-public-a"
    #         #     private_ips_count = 1
    #         #     security_groups = ["SG-2-WEB", "SG-FAKE"]
    #         #     tags = {
    #         #         NIC1_TAGS = "yes"
    #         #     }
    #         # }
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
        vpc_id      = "vpc-lab-dev-000"
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

