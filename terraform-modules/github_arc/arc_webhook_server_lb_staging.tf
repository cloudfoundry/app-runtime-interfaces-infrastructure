resource "kubernetes_secret_v1" "arc_ingress_ssl_staging" {
    metadata {
      name = "arc-ingress-staging"
      namespace = "actions-runner-system"
      }

    type = "kubernetes.io/tls"
    data = {
      "tls.key" = ""
      "tls.crt" = ""
      }
      depends_on = [helm_release.github_arc]

      #create empty secret at first and ignore contents later as secret is updated by letsencrypt
      lifecycle {
        ignore_changes = all
      }
    }


resource "kubernetes_manifest" "arc_letsencrypt_staging" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "arc-letsencrypt-staging"
      "namespace" = "actions-runner-system"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
        "email"  = "marcin.kubica@sap.com"
        "privateKeySecretRef" = {
          "name" = "arc-letsencrypt-staging"
        }
        "solvers" = [{
          "http01" = {
            "ingress" = {
              "name" = "arc-webhook-ingress-staging"
            }
          }
        }]
      }
    }
  }
  depends_on = [helm_release.cert_manager]
}



resource "kubernetes_ingress_v1" "arc_ingress_staging" {
  metadata {
    name      = "arc-webhook-ingress-staging"
    namespace = "actions-runner-system"
    annotations = {
      "kubernetes.io/ingress.allow-http"            = "true"
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = "${google_compute_global_address.arc_webhook_server_staging.name}"
      "cert-manager.io/issuer"                      = "arc-letsencrypt-staging"
    }
  }
  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = "actions-runner-controller-github-webhook-server"
              port {
                number = 80
              }
            }
          }
          path = "/actions-runner-controller-github-webhook-server"
          path_type = "Prefix"
        }
      }
    }
    tls {
      hosts       = [ trimsuffix("${google_dns_record_set.arc_webhook_server_staging.name}", ".")]
      secret_name = "arc-ingress-staging"
    }
    default_backend {
        service {
          name = "actions-runner-controller-github-webhook-server"
          port {
            number = 80
          }
        }
    }
  }
  depends_on = [
    kubernetes_secret_v1.arc_ingress_ssl_staging,
    kubernetes_manifest.arc_letsencrypt_staging,
    google_dns_record_set.arc_webhook_server_staging
     ]

}

