dependencies {
  paths = ["../app"]
}

locals {
  config = yamldecode(file("../config.yaml"))
}


remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "${local.config.gcs_bucket}"
    prefix         = "${local.config.gcs_prefix}/e2e-test-pipeline"
    project        = "${local.config.project}"
    location       = "${local.config.region}"
    # use for uniform bucket-level access
    # (https://cloud.google.com/storage/docs/uniform-bucket-level-access)
    enable_bucket_policy_only = true
  }
}

terraform {
  source = local.config.tf_modules.e2e_test
  }


inputs = {
  project = local.config.project
  region  = local.config.region
  zone    = local.config.zone

  gke_name = local.config.gke_name

  fly_target = local.config.gke_name
  fly_team = local.config.fly_team

  pipeline = "e2e-test"
  pipeline_job = "e2e-${local.config.gke_name}"

  credhub-test-secret-path = "/concourse/${local.config.fly_team}"
}