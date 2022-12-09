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

  gke_name = local.config.gke_name

  github_repo_name = local.config.github_repo_name
  github_repo_owner = local.config.github_repo_owner

  cert_manager_helm_version = local.config.cert_manager_helm_version
  github_arc_helm_version = local.config.github_arc_helm_version

  arc_github_access_token_name = local.config.arc_github_access_token_name
  arc_github_webhook_server_name = "${local.config.gke_name}-arc"
  arc_github_webhook_server_token_name =  "${local.config.arc_github_webhook_server_token_name}"

  arc_letsencrypt_notifications_email = local.config.arc_letsencrypt_notifications_email

  arc_letsencrypt_staging = local.config.arc_letsencrypt_staging

  webhook_server_dns_production = "${local.config.gke_name}-arc"
  webhook_server_dns_staging = "${local.config.gke_name}-arc-s"
  dns_zone   = local.config.dns_zone
  dns_domain = local.config.dns_domain
}

