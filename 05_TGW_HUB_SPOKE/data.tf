data "aws_caller_identity" "general" {
  provider = aws.aws25_general
}

data "aws_caller_identity" "dev" {
  provider = aws.aws25_dev
}

data "aws_caller_identity" "prod" {
  provider = aws.aws25_prod
}

data "aws_availability_zones" "test" {
  region = "us-east-2"
}

