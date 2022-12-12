data "google_secret_manager_secret_version" "arc_github_webhook_server_token" {
  project = var.project
  secret  = var.arc_github_webhook_server_token_name
}

resource "github_repository_webhook" "github_webhook" {
    for_each = { for repo in var.github_repos: repo.name => repo }

    # the way we use ../ is a workaround to achieve multiple repos
    # please see providers.tf file
    repository = "../${each.value.owner}/${each.value.name}"
    configuration {
      url = "https://${var.arc_github_webhook_server_name}.${var.arc_webhook_server_production_domain}/actions-runner-controller-github-webhook-server"
      content_type = "json"
      insecure_ssl = false
      secret = data.google_secret_manager_secret_version.arc_github_webhook_server_token.secret_data
    }
    active = true
    events = [ "workflow_job"]
}
