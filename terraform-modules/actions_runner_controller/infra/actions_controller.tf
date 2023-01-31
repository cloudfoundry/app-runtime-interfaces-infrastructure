data "google_secret_manager_secret_version" "arc_github_access_token" {
  project = var.project
  secret  = var.arc_github_access_token_name
}

data "google_secret_manager_secret_version" "arc_github_webhook_server_token" {
  project = var.project
  secret  = var.arc_github_webhook_server_token_name
}

resource "helm_release" "github_arc" {
  # https://github.com/actions-runner-controller/actions-runner-controller/blob/master/charts/actions-runner-controller/values.yaml
  name             = "actions-runner-controller"
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
  namespace        = "actions-runner-system"
  create_namespace = true
  version          = var.arc_helm_version
  recreate_pods    = true


  set {
    name  = "authSecret.create"
    value = true
  }

  set {
    name  = "authSecret.github_token"
    value = data.google_secret_manager_secret_version.arc_github_access_token.secret_data
  }

  set {
    name  = "githubWebhookServer.enabled"
    value = true
  }

  set {
    name  = "githubWebhookServer.service.type"
    value = "NodePort"
  }

  set {
    name  = "githubWebhookServer.secret.enabled"
    value = true
  }

  set {
    name  = "githubWebhookServer.secret.create"
    value = true
  }

  set {
    name  = "githubWebhookServer.secret.name"
    value = "arc-github-webhook-server-token"
  }

  set {
    name  = "githubWebhookServer.secret.github_webhook_secret_token"
    value = data.google_secret_manager_secret_version.arc_github_webhook_server_token.secret_data
  }

  set {
    name  = "image.actionsRunnerRepositoryAndTag"
    value = "summerwind/actions-runner:ubuntu-22.04"
  }

  depends_on = [helm_release.cert_manager, google_compute_firewall.arc_webhook]
}
