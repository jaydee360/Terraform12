fw_policy_config = {
#   test-policy = {
#     region = "us-east-2"
#     stateless_default_actions = ["aws:forward_to_sfe"]
#     stateless_fragment_default_actions = ["aws:forward_to_sfe"]
#     # stateful_default_actions = ["aws:pass"]
#     rule_order = "DEFAULT_ACTION_ORDER"
#   }
}

fw_config = {
    # test-fw = {
    #     region = "us-east-2"
    #     vpc_key = "vpc-inspection"
    #     subnet_keys = ["vpc-inspection-fw-subnet-a", "vpc-inspection-fw-subnet-b", "vpc-inspection-fw-subnet-c"]
    #     policy_key = "test-policy"
    #     logging_config = [
    #         {log_type = "FLOW", log_destination_type = "CloudWatchLogs", log_namespace_1 = "networkfirewall"},
    #         {log_type = "ALERT", log_destination_type = "CloudWatchLogs", log_namespace_1 = "networkfirewall"},
    #     ]
    # }
}

tgw_config = {
    tgw_hub = {
        # account = "aws25_dev"
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

flow_logs_config = {
    vpc_flow_log_test = {
        traffic_type            = "ALL"
        iam_role_key            = "vpc_flow_logs"
        log_destination_type    = "cloud-watch-logs"
        log_namespace_1         = "flowlog"
        log_namespace_2         = "vpc"
        log_namespace_3         = "shared"
        retention_in_days       = 7
    }
    vpc_edge = {
        traffic_type            = "ALL"
        iam_role_key            = "vpc_flow_logs"
        log_destination_type    = "cloud-watch-logs"
        log_namespace_1         = "flowlog"
        log_namespace_2         = "vpc"
        log_namespace_3         = "edge"
        retention_in_days       = 7
    }
    vpc_edge_public_subnet = {
        traffic_type            = "ALL"
        iam_role_key            = "vpc_flow_logs"
        log_destination_type    = "cloud-watch-logs"
        log_namespace_1         = "flowlog"
        log_namespace_2         = "subnet"
        log_namespace_3         = "edge_public"
        retention_in_days       = 7
    }
    vpc_inspection = {
        traffic_type            = "ALL"
        iam_role_key            = "vpc_flow_logs"
        log_destination_type    = "cloud-watch-logs"
        log_namespace_1         = "flowlog"
        log_namespace_2         = "vpc"
        log_namespace_3         = "inspection"
        retention_in_days       = 7
    }
}

vpc_config = {
    vpc-edge = {
        region = "us-east-2"
        vpc_cidr = "10.0.0.0/16"
        create_igw = true
        flow_logs_config = "vpc_edge"
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
                flow_logs_config = "vpc_edge_public_subnet"
                #create_natgw   = true
            }
            vpc-edge-public-subnet-b = {
                subnet_cidr    = "10.0.5.0/24"
                az             = "b"
                routing_policy = "edge_public_subnets"
                flow_logs_config = "vpc_edge_public_subnet"
                #create_natgw   = true
            }
            vpc-edge-public-subnet-c = {
                subnet_cidr    = "10.0.6.0/24"
                az             = "c"
                routing_policy = "edge_public_subnets"
                flow_logs_config = "vpc_edge_public_subnet"
                #create_natgw   = true
            }
        }
    }
    vpc-inspection = {
        region = "us-east-2"
        vpc_cidr = "10.1.0.0/16"
        flow_logs_config = "vpc_inspection"
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
        #flow_logs_config = "vpc_flow_log_test"
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
        #flow_logs_config = "vpc_flow_log_test"
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
        #flow_logs_config = "vpc_flow_log_test"
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

ec2_profiles = {
    edge_public_webserver = {
        # most of the paramters for this server type are now set using ec2_profile templates
        ami_by_region = {
            us-east-1 = "ami-0c3e8df62015275ea"
            us-east-2 = "ami-0611dd377055177a9"
        }
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "terraform-default"
        iam_instance_profile = "PRF__ec2-ssm-role"
        user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                routing_policy = "edge_public_subnets"
                security_groups = ["webserver_frontend"]
                assign_eip = true
            }
        }
        tags = {
            Role = "frontend"
            Source  = "edge_public_webserver_profile"
        }
    }
    private_app_server = {
        # most of the paramters for this server type are now set using ec2_profile templates
        ami_by_region = {
            us-east-1 = "ami-0c3e8df62015275ea"
            us-east-2 = "ami-0611dd377055177a9"
        }
        ami = "ami-0150ccaf51ab55a51"
        instance_type = "t3.micro"
        key_name = "terraform-default"
        iam_instance_profile = "PRF__ec2-ssm-role"
        user_data_script = "server-script.sh"
        network_interfaces = {
            "nic0" = {
                routing_policy = "spoke_app_subnets"
                security_groups = ["webserver_frontend"]
            }
        }
        tags = {
            Role = "frontend"
            Source  = "private_app_server"
        }
    }
}

ec2_instances = {
    web_00 = {
        region = "us-east-2"
        ec2_profile = "edge_public_webserver"
        network_interfaces = {
            "nic0" = {
                vpc = "vpc-edge"
                az = "a"
            }
        }
    }
}

prefix_list_config = {
    JD-HOME-LAB = {
        name           = "JD-HOME-LAB"
        region          = "us-east-2"
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
        vpc_id      = "vpc-edge"
        region      = "us-east-2"
        description = "webserver_frontend SG"
        ingress_ref = ["WEB_FRONTEND_IN", "ADMIN_IN", "ICMP_IN"]
        egress_ref = ["ANY_OUT"]
        tags = {
            TAG = "SECURITY_GROUPS > WEBSERVER_FRONTEND"
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
            #referenced_security_group_id = "test_ref_sg_id"
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
    "ICMP_IN" = [
        {
            description = "SHARED-ICMP-IN"
            from_port = -1
            to_port = -1
            ip_protocol = "icmp"
            prefix_list_id = "JD-HOME-LAB"
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

iam_policy_config = {
    write-cloudwatch-logs = {
        name        = "write-cloudwatch-logs"
        description = "write-logcloudwatchs-logs-policy"
        policy = <<EOT
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "WriteCloudWatchVPCFlowLogs",
                        "Effect": "Allow",
                        "Action": [
                            "logs:CreateLogGroup",
                            "logs:CreateLogStream",
                            "logs:PutLogEvents",
                            "logs:DescribeLogGroups",
                            "logs:DescribeLogStreams"
                        ],
                        "Resource": ["*"]
                    }
                ]
            }
        EOT
    }
    # s3-read-only = {
    #     name        = "s3-read-only"
    #     description = "Allow read-only access to all S3 buckets"
    #     policy = <<EOT
    #         {
    #             "Version": "2012-10-17",
    #             "Statement": [
    #             {
    #                 "Sid": "S3ReadOnlyAccess",
    #                 "Effect": "Allow",
    #                 "Action": [
    #                 "s3:GetObject",
    #                 "s3:ListBucket"
    #                 ],
    #                 "Resource": [
    #                 "*"
    #                 ]
    #             }
    #             ]
    #         }
    #     EOT
    # }
    # dynamodb-read-write = {
    #     name = "dynamodb-read-write"
    #     description = "Grants full CRUD access to all DynamoDB tables in the account, including indexes and streams"
    #     policy = <<EOT
    #         {
    #             "Version": "2012-10-17",
    #             "Statement": [
    #                 {
    #                 "Sid": "DynamoDBTableAccess",
    #                 "Effect": "Allow",
    #                 "Action": [
    #                     "dynamodb:BatchGetItem",
    #                     "dynamodb:BatchWriteItem",
    #                     "dynamodb:ConditionCheckItem",
    #                     "dynamodb:PutItem",
    #                     "dynamodb:DescribeTable",
    #                     "dynamodb:DeleteItem",
    #                     "dynamodb:GetItem",
    #                     "dynamodb:Scan",
    #                     "dynamodb:Query",
    #                     "dynamodb:UpdateItem"
    #                 ],
    #                 "Resource": [
    #                     "arn:aws:dynamodb:*:123456789012:table/*",
    #                     "arn:aws:dynamodb:*:123456789012:table/*/index/*"
    #                 ]
    #                 },
    #                 {
    #                 "Sid": "DynamoDBStreamAccess",
    #                 "Effect": "Allow",
    #                 "Action": [
    #                     "dynamodb:GetShardIterator",
    #                     "dynamodb:Scan",
    #                     "dynamodb:Query",
    #                     "dynamodb:DescribeStream",
    #                     "dynamodb:GetRecords",
    #                     "dynamodb:ListStreams"
    #                 ],
    #                 "Resource": "arn:aws:dynamodb:*:123456789012:table/*/stream/*"
    #                 },
    #                 {
    #                 "Sid": "DynamoDBDescribeLimitsAccess",
    #                 "Effect": "Allow",
    #                 "Action": "dynamodb:DescribeLimits",
    #                 "Resource": "*"
    #                 }
    #             ]
    #         }
    #     EOT
    # }
}



iam_role_config = {
    ec2_ssm = {
        name                    = "ec2-ssm-role"
        description             = "EC2 role for SSM acces"
        principal               = {services = ["ec2.amazonaws.com"]}
        aws_managed_policies    = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
        iam_instance_profile = true
    }
    vpc_flow_logs = {
        name        = "vpc-flow-logs-role"
        description = "Role for publishing VPC Flow Logs to CloudWatch Logs"
        principal   = {services = ["vpc-flow-logs.amazonaws.com"]}
        inline_policies = {
            flowlogs_to_cloudwatch = {
                statement = [
                    {
                        Sid     = "FlowLogsCWLogs"
                        Effect  = "Allow"
                        Action = [
                                    "logs:CreateLogGroup",
                                    "logs:CreateLogStream",
                                    "logs:PutLogEvents",
                                    "logs:DescribeLogGroups",
                                    "logs:DescribeLogStreams",
                                ]
                        Resource = ["*"]
                    }
                ]
            }
        }
        iam_instance_profile = false
    }
    # lambda_exec = {
    #     name                    = "lambda-exec-role"
    #     description             = "Role for Lambda execution"
    #     principal               = {services = ["lambda.amazonaws.com"]}
    #     aws_managed_policies    = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
    #     iam_instance_profile    = false
    # }
    # data_pipeline = {
    #     name        = "data-pipeline-role"
    #     description = "Role for data pipeline tasks"
    #     principal   = {services = ["ec2.amazonaws.com"]}
    #     custom_managed_policies = ["s3-read-only", "dynamodb-read-write"]
    #     iam_instance_profile    = true
    # }
    # audit_role = {
    #     name                    = "audit-role"
    #     description             = "Role for audit logging"
    #     principal               = {accounts = ["123456789012"]}
    #     inline_policies = {
    #         audit_inline = {
    #             statement = [
    #                 {
    #                     Effect   = "Allow"
    #                     Action   = ["cloudtrail:LookupEvents"]
    #                     Resource = ["*"]
    #                 }
    #             ]
    #         }
    #     }
    #     iam_instance_profile = false 
    # }
    # app_server = {
    #     name                    = "app-server-role"
    #     description             = "Role for application servers"
    #     principal               = {services = ["ec2.amazonaws.com"]}
    #     aws_managed_policies    = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
    #     custom_managed_policies = ["write-cloudwatch-logs"]
    #     inline_policies = {
    #         s3_upload_inline = {
    #             statement = [
    #                 {
    #                     Sid      = "S3Upload"
    #                     Effect   = "Allow"
    #                     Action   = ["s3:PutObject"]
    #                     Resource = ["arn:aws:s3:::app-bucket/*"]
    #                 }
    #             ]
    #         }
    #     }
    #     iam_instance_profile = true
    # }
    # analytics = {
    #     name                    = "analytics-role"
    #     description             = "Role for analytics workloads"
    #     principal               = {services = ["glue.amazonaws.com"]}
    #     aws_managed_policies    = ["arn:aws:iam::aws:policy/AmazonAthenaFullAccess"]
    #     inline_policies = {
    #         glue_inline = {
    #             statement = [
    #                 {
    #                     Effect   = "Allow"
    #                     Action   = ["glue:CreateDatabase", "glue:CreateTable"]
    #                     Resource = ["*"]
    #                 }
    #             ]
    #         }
    #         logs_inline = {
    #             statement = [
    #                 {
    #                     Effect   = "Allow"
    #                     Action   = ["logs:CreateLogGroup", "logs:PutLogEvents"]
    #                     Resource = ["*"]
    #                 }
    #             ]
    #         }
    #     }
    #     iam_instance_profile = false
    # }
}

aws_cloudwatch_log_group_config = [
    {
        region            = "us-east-2"
        log_namespace_1   = "networkfirewall"
        log_namespace_2   = "test-fw"
        log_namespace_3   = "flow"
        retention_in_days = 7
    },
    {
        region            = "us-east-2"
        log_namespace_1   = "networkfirewall"
        log_namespace_2   = "test-fw"
        log_namespace_3   = "alert"
        retention_in_days = 7
    }
]

