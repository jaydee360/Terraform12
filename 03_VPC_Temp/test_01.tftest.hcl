

run "jdtest" {
    command = apply

    variables {
      aws_profile = "terraform_dev"
    }

    assert {
      condition = length(aws_vpc.main) == 2
      error_message = "Expected 2 VPCs" 
    }

    assert {
        condition     = length(aws_subnet.main) == 6
        error_message = "Expected 6 subnets"
    }
}

run "vpc_lab_dev_000" {
  command = apply

  variables {
      aws_profile = "terraform_dev"
  }

  assert {
    condition     = aws_vpc.main["vpc-lab-dev-000"].cidr_block == "10.0.0.0/16"
    error_message = "'vpc-lab-dev-000' must have CIDR 10.0.0.0/16"
  }

  assert {
    condition     = aws_vpc.main["vpc-lab-dev-000"].enable_dns_support && aws_vpc.main["vpc-lab-dev-000"].enable_dns_hostnames
    error_message = "DNS support & DNS hostnames must be enabled"
  }

  assert {
    condition = contains(keys(aws_internet_gateway.main), "vpc-lab-dev-000")
    error_message = "IGW for vpc-lab-dev-000 must be created"
  }

  assert {
    condition = contains(keys(aws_internet_gateway.main), "vpc-lab-dev-000") && (aws_internet_gateway_attachment.main["vpc-lab-dev-000"].vpc_id == aws_vpc.main["vpc-lab-dev-000"].id)
    error_message = "IGW must be created & attached to the VPC"
  }

  assert {
    condition     = aws_internet_gateway.main["vpc-lab-dev-000"].tags["IGW_TAG"] == "yes"
    error_message = "IGW must have 'IGW_TAG' = 'yes'"
  }

  assert {
    condition     = contains(keys(aws_internet_gateway.main["vpc-lab-dev-000"].tags), "Name")
    error_message = "IGW must have 'Name' Tag"
  }


}

run "vpc_lab_dev_100" {
  command = apply

  variables {
    aws_profile = "terraform_dev"
  }

  assert {
    condition     = aws_vpc.main["vpc-lab-dev-100"].cidr_block == "10.1.0.0/16"
    error_message = "'vpc-lab-dev-100' must have CIDR 10.1.0.0/16"
  }

  assert {
    condition     = !contains(keys(aws_internet_gateway.main), "vpc-lab-dev-100")
    error_message = "IGW should NOT be created for vpc-lab-dev-100"
  }
}
