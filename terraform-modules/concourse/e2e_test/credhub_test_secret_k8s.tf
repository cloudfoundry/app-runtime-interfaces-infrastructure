data "kubernetes_secret_v1" "credhub_secret" {
  metadata {
    name      = "credhub-admin-client-credentials"
    namespace = "concourse"
  }
  binary_data = {
    password = ""
  }
}

data "kubernetes_secret_v1" "credhhub_ca_cert" {
  metadata {
    name      = "credhub-root-ca"
    namespace = "concourse"
  }
  binary_data = {
    certificate = ""
  }
}

resource "random_id" "credhub_cli" {
  byte_length = 3
  keepers = {
    date = timestamp()
  }
}

resource "kubernetes_job" "credhub_cli" {
# delete all previous test secret and create new random one

  metadata {
    name      = "${var.credhub-test-secret-prefix}-${random_id.credhub_cli.hex}"
    namespace = "default"
  }

  spec {
    ttl_seconds_after_finished = "0"
    template {
      metadata {}
      spec {
        restart_policy = "Never"
        container {
          image = "cloudfoundry/cf-deployment-concourse-tasks:v19.0.0"
          name  = "credhub-cli"

          command = [
            "/bin/bash", "-c",
            "for c in $(credhub find |grep 'credhub-cli-tf' | sed 's/\\- name\\: //'); do credhub delete -n $c; done; credhub set -n ${var.credhub-test-secret-path}/${var.credhub-test-secret-prefix}-${random_id.credhub_cli.hex} -t value -v ${var.credhub-test-secret-prefix}-${random_id.credhub_cli.hex}-value"
          ]

          env {
            name  = "CREDHUB_SECRET"
            value = base64decode(data.kubernetes_secret_v1.credhub_secret.binary_data.password)
          }
          env {
            name  = "CREDHUB_CA_CERT"
            value = trimspace(base64decode(data.kubernetes_secret_v1.credhhub_ca_cert.binary_data.certificate))
          }
          env {
            name  = "CREDHUB_CLIENT"
            value = "credhub_admin_client"
          }
          env {
            name  = "CREDHUB_SERVER"
            value = "https://credhub.concourse.svc.cluster.local:9000"
          }
        }
      }
    }
  }


}

