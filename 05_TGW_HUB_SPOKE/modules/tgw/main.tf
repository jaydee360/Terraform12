resource "aws_ec2_transit_gateway" "test" {
  provider = aws
  region = var.tgw_object.region
  amazon_side_asn = var.tgw_object.amazon_side_asn
  description = var.tgw_object.description
  auto_accept_shared_attachments = var.tgw_object.auto_accept_shared_attachments
  tags = merge(
    {Name = var.tgw_key},
    var.tgw_object.tags,
    var.default_tags
  )
}