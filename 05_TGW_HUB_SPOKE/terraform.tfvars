tgw_config = {
    tgw-dev-hub-us-east-2 = {
        account = "aws25_dev"
        region = "us-east-2"
        amazon_side_asn = 64512
        description = "dev tgw twat"
        auto_accept_shared_attachments = "enable"
        tags = {
            type = "public"
            TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_000"
        }
    }
    tgw-prod-hub-us-east-2 = {
        account = "aws25_prod"
        region = "us-west-1"
        amazon_side_asn = 64512
        description = "dev tgw twat"
        auto_accept_shared_attachments = "enable"
        tags = {
            type = "public"
            TAG = "This tag is from VPC_CONFIG > VPC_000 > SUBNET > PUBLIC_SUBNET_000"
        }
    }
}
