# https://cert-manager.io/docs/tutorials/getting-started-with-cert-manager-on-google-kubernetes-engine-using-lets-encrypt-for-ingress-ssl/
# https://kosyfrances.com/ingress-gce-letsencrypt/
resource "kubernetes_manifest" "letsencrypt_staging" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "letsencrypt-staging"
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
              "class" = "ingress-gce"
            }
          }
        }]
      }
    }
  }
  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "letsencrypt_production" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "letsencrypt-production"
      "namespace" = "actions-runner-system"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "email"  = "marcin.kubica@sap.com"
        "privateKeySecretRef" = {
          "name" = "arc-letsencrypt-production"
        }
        "solvers" = [{
          "http01" = {
            "ingress" = {
              "class" = "ingress-gce"
            }
          }
        }]
      }
    }
  }
  depends_on = [helm_release.cert_manager]
}


