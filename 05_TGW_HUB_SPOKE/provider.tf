provider "aws" {
  region  = var.aws_region
  profile = "terraform_general"
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform_general"
  alias = "aws25_general"
}

provider "aws" {
  region = var.aws_region
  profile = "terraform_dev"
  alias = "aws25_dev"
}

provider "aws" {
  region = var.aws_region
  profile = "terraform_prod"
  alias = "aws25_prod"
}
