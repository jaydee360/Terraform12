variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
  default     = "terraform"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_iam_user" "my_user" {
  name = "TF-Test-User"
}

resource "aws_iam_policy" "my_policy" {
  name        = "TF-Test-Policy"
  description = "A test policy for Terraform"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ec2:GetResourcePolicy",
          "ec2:GetIpamResourceCidrs",
          "ec2:GetIpamPoolCidrs",
          "ec2:GetInstanceUefiData",
          "ec2:ExportClientVpnClientConfiguration",
          "ec2:GetCapacityReservationUsage",
          "ec2:GetNetworkInsightsAccessScopeAnalysisFindings",
          "ec2:GetRouteServerPropagations",
          "ec2:GetConsoleScreenshot",
          "ec2:GetConsoleOutput",
          "ec2:ExportClientVpnClientCertificateRevocationList",
          "ec2:GetLaunchTemplateData",
          "ec2:GetFlowLogsIntegrationTemplate",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:GetRouteServerAssociations",
          "ec2:GetIpamDiscoveredResourceCidrs",
          "ec2:GetActiveVpnTunnelStatus",
          "ec2:GetManagedPrefixListEntries",
          "ec2:GetIpamDiscoveredPublicAddresses",
          "ec2:GetCoipPoolUsage",
          "ec2:ExportVerifiedAccessInstanceClientConfiguration",
          "ec2:GetNetworkInsightsAccessScopeContent",
          "ec2:GetReservedInstancesExchangeQuote",
          "ec2:GetAssociatedEnclaveCertificateIamRoles",
          "ec2:GetIpamAddressHistory",
          "ec2:GetPasswordData",
          "ec2:GetAssociatedIpv6PoolCidrs",
          "ec2:GetDeclarativePoliciesReportSummary",
          "ec2:GetManagedPrefixListAssociations",
          "ec2:GetInstanceTpmEkPub",
          "ec2:GetIpamDiscoveredAccounts",
          "ec2:GetRouteServerRoutingDatabase"
        ],
        "Resource" : [
          "arn:aws:acm:*:131948736146:certificate/*",
          "arn:aws:ec2:*:131948736146:placement-group/*",
          "arn:aws:ec2:*:131948736146:client-vpn-endpoint/*",
          "arn:aws:ec2:*:131948736146:route-server/*",
          "arn:aws:ec2:*:131948736146:route-table/*",
          "arn:aws:ec2:*:131948736146:verified-access-instance/*",
          "arn:aws:ec2:*:131948736146:coip-pool/*",
          "arn:aws:ec2:*:131948736146:instance/*",
          "arn:aws:ec2:*:131948736146:prefix-list/*",
          "arn:aws:ec2:*:131948736146:network-insights-access-scope-analysis/*",
          "arn:aws:ec2:*:131948736146:network-insights-access-scope/*",
          "arn:aws:ec2::131948736146:ipam-resource-discovery/*",
          "arn:aws:ec2:*:131948736146:vpc/*",
          "arn:aws:ec2:*:131948736146:reserved-instances/*",
          "arn:aws:ec2:*:131948736146:verified-access-group/*",
          "arn:aws:ec2::131948736146:ipam-pool/*",
          "arn:aws:ec2::131948736146:ipam-scope/*",
          "arn:aws:ec2:*:131948736146:vpc-flow-log/*",
          "arn:aws:ec2:*:131948736146:vpn-connection/*",
          "arn:aws:ec2:*:131948736146:declarative-policies-report/*",
          "arn:aws:ec2:*:131948736146:capacity-reservation/*",
          "arn:aws:ec2:*:131948736146:ipv6pool-ec2/*"
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "ec2:GetDefaultCreditSpecification",
          "ec2:GetSerialConsoleAccessStatus",
          "ec2:GetImageBlockPublicAccessState",
          "ec2:StartDeclarativePoliciesReport",
          "ec2:GetAllowedImagesSettings",
          "ec2:GetEbsEncryptionByDefault",
          "ec2:GetSnapshotBlockPublicAccessState",
          "ec2:GetSpotPlacementScores",
          "ec2:GetHostReservationPurchasePreview",
          "ec2:GetEbsDefaultKmsKeyId",
          "ec2:GetSubnetCidrReservations",
          "ec2:GetAwsNetworkPerformanceData"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "my_policy_attachment" {
  name       = "TF-Test-User-Policy-Attachment"
  policy_arn = aws_iam_policy.my_policy.arn
  users      = [aws_iam_user.my_user.name]
}

# resource "aws_iam_user_policy_attachment" "my_user_policy_attachment" {
#     user       = aws_iam_user.my_user.name
#     policy_arn = aws_iam_policy.my_policy.arn
# }
