data "google_secret_manager_secret_version" "arc_github_webhook_server_token" {
  project = var.project
  secret  = var.arc_github_webhook_server_token_name
}

data "github_repository" "github_repo" {
    full_name = "${var.github_repo_owner}/${var.github_repo_name}"
}

resource "github_repository_webhook" "github_webhook" {
    repository = data.github_repository.github_repo.name
    configuration {
      url = "https://${var.arc_github_webhook_server_name}.${var.arc_webhook_server_production_domain}/actions-runner-controller-github-webhook-server"
      content_type = "json"
      insecure_ssl = false
      secret = data.google_secret_manager_secret_version.arc_github_webhook_server_token.secret_data
    }
    active = true
    events = [ var.arc_github_webhook_events ]
}