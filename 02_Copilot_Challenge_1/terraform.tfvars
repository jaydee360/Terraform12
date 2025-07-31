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