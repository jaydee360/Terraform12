module "aws25_dev" {
  source = "./modules/tgw"
  providers = {aws = aws.aws25_dev}
  for_each = {for k, v in var.tgw_config : k => v if v.account == "aws25_dev"}
  tgw_key = each.key
  tgw_object = each.value
  default_tags = var.default_tags
}

module "aws25_prod" {
  source = "./modules/tgw"
  providers = {aws = aws.aws25_prod}
  for_each = {for k, v in var.tgw_config : k => v if v.account == "aws25_prod"}
  tgw_key = each.key
  tgw_object = each.value
  default_tags = var.default_tags
}
