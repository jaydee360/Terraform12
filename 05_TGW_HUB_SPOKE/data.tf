data "aws_caller_identity" "general" {
  provider = aws.aws25_general
}

data "aws_caller_identity" "dev" {
  provider = aws.aws25_dev
}

data "aws_caller_identity" "prod" {
  provider = aws.aws25_prod
}

output "callers" {
  value = {
    general = data.aws_caller_identity.general
    dev = data.aws_caller_identity.dev
    prod = data.aws_caller_identity.prod
  }
}