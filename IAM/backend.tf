terraform {
    backend "s3" {
        bucket         = "aws25-general-terraform-lab-1"
        key            = "IAM/state.tfstate"
        region         = "us-east-1"
        profile        = "terraform"
    }
    required_providers {
    aws = {
      version = "6.3.0"
    }
  }
}