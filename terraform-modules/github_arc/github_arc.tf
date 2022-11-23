data "google_secret_manager_secret_version" "gsm_github_access_token" {
  project = var.project
  secret  = var.gsm_github_access_token_name
}

resource "helm_release" "github_arc" {
  name             = "actions-runner-controller"
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
  namespace        = "actions-runner-system"
  create_namespace = true
  version          = var.github_arc_helm_version
  recreate_pods    = true
  #values           = ["${file("github_arc_values.yaml")}"]

  # https://github.com/actions-runner-controller/actions-runner-controller/blob/master/charts/actions-runner-controller/values.yaml

  set {
    name  = "authSecret.create"
    value = true
  }

  set {
    name  = "authSecret.github_token"
    value = data.google_secret_manager_secret_version.gsm_github_access_token.secret_data
  }


  depends_on = [helm_release.cert_manager]
}
