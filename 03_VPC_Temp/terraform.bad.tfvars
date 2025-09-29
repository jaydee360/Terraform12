vpc_config = {
    "vpc-lab-dev-000" = {
        vpc_cidr = "10.0.0.0/16"
        tags = {
        }
        igw = {
            create = true
            attach = true
            tags = {
            }
        }
        subnets = {
            "snet-lab-dev-000-public-a" = {
                az          = "a"
                subnet_cidr = "10.0.0.0/24"
                tags = {
                    "type" = "public"
                }
                has_route_table = true
                has_nat_gw = true
            }
            "snet-lab-dev-000-public-b" = {
                az          = "b"
                subnet_cidr = "10.0.1.0/24"
                tags = {
                    "type" = "public"
                }
                has_route_table = true
                has_nat_gw = true
            }
            "snet-lab-dev-000-public-c" = {
                az          = "c"
                subnet_cidr = "10.0.2.0/24"
                tags = {
                    "type" = "public"
                }
                has_route_table = true
                has_nat_gw = true
            }
            "snet-lab-dev-000-public-d" = {
                az          = "c"
                subnet_cidr = "10.0.3.0/24"
                tags = {
                    "type" = "public"
                }
                has_route_table = true
                has_nat_gw = true
            }
            "snet-lab-dev-000-private-a" = {
                az          = "a"
                subnet_cidr = "10.0.4.0/24"
                tags = {
                    "type" = "private"
                }
                has_route_table = true
            }
            "snet-lab-dev-000-private-b" = {
                az          = "b"
                subnet_cidr = "10.0.5.0/24"
                tags = {
                    "type" = "private"
                }
                has_route_table = true
            }
            "snet-lab-dev-000-private-c" = {
                az          = "c"
                subnet_cidr = "10.0.6.0/24"
                tags = {
                    "type" = "private"
                }
                has_route_table = true
            }
        }
    }
    "vpc-lab-dev-100" = {
        vpc_cidr = "10.1.0.0/16"
        tags = {
        }
        igw = {
            create = true
            attach = false
            tags = {
            }
        }
        subnets = {
            "snet-lab-dev-100-public-a" = {
                az          = "a"
                subnet_cidr = "10.1.0.0/24"
                tags = {
                }
                has_route_table = true
                has_nat_gw = true
            }
            "snet-lab-dev-100-public-b" = {
                az          = "b"
                subnet_cidr = "10.1.1.0/24"
                tags = {
                }
                has_route_table = true
            }
            "snet-lab-dev-100-public-c" = {
                az          = "c"
                subnet_cidr = "10.1.2.0/24"
                tags = {
                }
                has_route_table = true
            }
            "snet-lab-dev-100-private-a" = {
                az          = "a"
                subnet_cidr = "10.1.4.0/24"
                tags = {
                }
                has_route_table = true
            }
            "snet-lab-dev-100-private-b" = {
                az          = "b"
                subnet_cidr = "10.1.5.0/24"
                tags = {
                }
                has_route_table = true
            }
            "snet-lab-dev-100-private-c" = {
                az          = "c"
                subnet_cidr = "10.1.6.0/24"
                tags = {
                }
                has_route_table = true
            }
        }
    }
}

route_table_config = {
    "vpc-lab-dev-000__snet-lab-dev-000-public-a" = {
        inject_igw = true
    }
    "vpc-lab-dev-000__snet-lab-dev-000-public-b" = {
        inject_igw = true
    }
    "vpc-lab-dev-000__snet-lab-dev-000-public-c" = {
        inject_igw = true
    }
    "vpc-lab-dev-000__snet-lab-dev-000-private-a" = {
        inject_nat = true
    }
    "vpc-lab-dev-000__snet-lab-dev-000-private-b" = {
        inject_nat = true
    }
    "vpc-lab-dev-000__snet-lab-dev-000-private-c" = {
        inject_nat = true
    }
    "vpc-lab-dev-100__snet-lab-dev-100-public-a" = {
        inject_igw = true
    }
    "vpc-lab-dev-100__snet-lab-dev-100-public-b" = {
        inject_igw = true
    }
    "vpc-lab-dev-100__snet-lab-dev-100-public-c" = {
        inject_igw = true
    }
    "vpc-lab-dev-100__snet-lab-dev-100-private-a" = {
        inject_nat = true
    }
    "vpc-lab-dev-100__snet-lab-dev-100-private-b" = {
        inject_nat = true
    }
    "vpc-lab-dev-100__snet-lab-dev-100-private-c" = {
        inject_nat = true
    }
    "vpc-lab-dev-100__snet-lab-dev-100-private-d" = {
        inject_nat = true
    }
}