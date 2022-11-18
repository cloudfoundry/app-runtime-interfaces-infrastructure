remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "app-runtime-interfaces-dns"
    prefix         = "zone-app-runtime-interfaces"
    project        = "app-runtime-interfaces-wg"
    location       = "europe-west3"
    enable_bucket_policy_only = true
  }
}

inputs = {
    project = "app-runtime-interfaces-wg"
}