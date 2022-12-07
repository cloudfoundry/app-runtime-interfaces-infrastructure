data "github_repository" "github_repo" {
    full_name = "${var.github_repo_owner}/${var.github_repo_name}"
}

resource "github_repository_webhook" "github_webhook" {
    repository = data.github_repository.github_repo.name
    configuration {
      url = "https://${trimsuffix("${google_dns_record_set.arc_webhook_server_production.name}", ".")}/actions-runner-controller-github-webhook-server"
      content_type = "json"
      insecure_ssl = false
      secret = data.google_secret_manager_secret_version.arc_github_webhook_server_token.secret_data
    }
    active = true
    events = [ "workflow_job" ]
}