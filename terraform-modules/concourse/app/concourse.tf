data "helm_template" "concourse" {
  name        = "concourse"
  repository  = "https://concourse-charts.storage.googleapis.com/"
  chart       = "concourse"
  version     = var.concourse_helm_version
  values      = ["${file("files/${var.gke_workers_pool_machine_type}.yml")}"]

  set {
    name  = "concourse.web.externalUrl"
    value = "https://${var.load_balancer_dns}"
  }

  set {
    name  = "web.service.api.loadBalancerIP"
    value = var.load_balancer_ip
  }

  set {
    name  = "concourse.web.auth.mainTeam.github.team"
    value = var.concourse_github_mainTeam
  }

  set {
    name  = "concourse.web.auth.mainTeam.github.user"
    value = var.concourse_github_mainTeamUser
  }

  set {
    # For security reasons, remove any local users
    name  = "concourse.web.auth.mainTeam.localUser"
    value = ""
  }

  set {
    name = "worker.replicas"
    value = var.gke_workers_pool_node_count
  }

  set {
    name = "worker.resources.requests.memory"
    value = var.gke_workers_min_memory
  }

  set {
    name = "web.replicas"
    value = var.gke_default_pool_node_count
  }

  set {
    name = "concourse.worker.runtime"
    value = "containerd"
  }
}

data "carvel_ytt" "concourse_app" {

  files = [ "files/config/concourse" ]

  config_yaml = data.helm_template.concourse.manifest

  values = {
    "google.project_id" = var.project
    "google.region"     = var.region
  }
 }

resource "carvel_kapp" "concourse_app" {
  app          = "concourse-app"
  namespace    = "concourse"
  # helm chart uses "policy/v1beta1" version for "PodDisruptionBudget" resource which is not valid anymore -> replace with "policy/v1"
  # https://github.com/concourse/concourse-chart/blob/c92075294c39a20fd48e0c5cc4533a2a59adfc70/templates/worker-policy.yaml#L2
  config_yaml  = replace(data.carvel_ytt.concourse_app.result, "policy/v1beta1", "policy/v1")
  diff_changes = true

  depends_on = [kubernetes_secret_v1.github_oauth, carvel_kapp.credhub_uaa]
}

