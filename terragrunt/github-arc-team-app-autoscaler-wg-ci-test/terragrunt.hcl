locals {
  config = yamldecode(file("./config.yaml"))
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "${local.config.gcs_bucket}"
    prefix         = "${local.config.gcs_prefix}"
    project        = "${local.config.project}"
    location       = "${local.config.region}"
    # use for uniform bucket-level access
    # (https://cloud.google.com/storage/docs/uniform-bucket-level-access)
    enable_bucket_policy_only = true
  }
}

# git for teams
terraform {
  source = local.config.tf_modules.github_arc
}

inputs = {
  project = local.config.project
  region  = local.config.region
  zone    = local.config.zone

  team_name = local.config.team_name

  github_repo_name = local.config.github_repo_name
  github_repo_owner = local.config.github_repo_owner

  gke_name = local.config.gke_name
  github_arc_workers_pool_machine_type = local.config.github_arc_workers_pool_machine_type
  github_arc_workers_pool_node_count = local.config.github_arc_workers_pool_node_count
  github_arc_workers_pool_autoscaling_max = local.config.github_arc_workers_pool_autoscaling_max
  github_arc_workers_pool_ssd_count = local.config.github_arc_workers_pool_ssd_count
  gke_arc_storage_type = local.config.gke_arc_storage_type

  hpa_scaleup_trigger_duration = local.config.hpa_scaleup_trigger_duration
  hpa_scaledown_delay_seconds = local.config.hpa_scaledown_delay_seconds
  runnerset_resource_request_cpu = local.config.runnerset_resource_request_cpu
  runnerset_resource_request_mem = local.config.runnerset_resource_request_mem
  runnerset_resource_limits_cpu = local.config.runnerset_resource_limits_cpu
  runnerset_resource_limits_mem = local.config.runnerset_resource_limits_mem

  arc_github_webhook_server_name = "${local.config.gke_name}-arc"
  arc_github_webhook_server_token_name =  "${local.config.arc_github_webhook_server_token_name}"

  arc_webhook_server_production_domain = "${local.config.arc_webhook_server_production_domain}"
}

