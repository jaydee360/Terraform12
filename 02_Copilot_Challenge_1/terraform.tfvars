  ec2_security_group_rules = {
    "JD-LAB-WEB-US-E-1" = {
      ingress = [
        {
          description = "80-IN"
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_block =  "0.0.0.0/0" 
        },
        {
          description = "443-IN"
          from_port = 443
          to_port = 443
          protocol = "tcp"
          cidr_block =  "0.0.0.0/0" 
        },
        {
          description = "22-IN"
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_block =  "0.0.0.0/0" 
        }
      ]
      egress = [
        {
          description = "ANY-OUT"
          protocol = "-1"
          cidr_block =  "0.0.0.0/0" 
        }
      ]
    },
    "JD-LAB-DB-US-E-1" = {
      ingress = [
        {
          description = "1433-IN"
          from_port = 1433
          to_port = 1433
          protocol = "tcp"
          cidr_block =  "10.0.0.0/16" 
        },
        {
          description = "3389-IN"
          from_port = 3389
          to_port = 3389
          protocol = "tcp"
          cidr_block =  "10.0.0.0/16" 
        }
      ]
      egress = [
        {
          description = "ANY-OUT"
          protocol = "-1"
          cidr_block =  "0.0.0.0/0" 
        }
      ]
    }
  }


api_rate_limit_config_alt = {
    dev = {
      limit_per_minute = 60
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
    stage = {
      limit_per_minute = 90
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
    prod = {
      limit_per_minute = 120
      burst_size = 240
      retry_policy = {
        max_retries = 5
        interval_seconds = 5
      }
    }
  } 

/*   feature_flags = {
    new_ui      = true
    beta_mode   = [false, "disabled by admin"]
    OldUI       = false
    TestFeature = [true, "Enabled by JD"]
    NewThing    = [false, "TBC"]
  }
 */