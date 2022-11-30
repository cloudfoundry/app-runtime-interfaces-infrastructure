#https://cert-manager.io/docs/tutorials/getting-started-with-cert-manager-on-google-kubernetes-engine-using-lets-encrypt-for-ingress-ssl/

# resource "kubernetes_secret_v1" "arc_letsencrypt_secret" {
#     metadata {
#       name = "arc-webhook-server-ssl"
#       namespace = "actions-runner-system"
#       }

#     type = "kubernetes.io/tls"
#     data = {
#       "tls.key" = ""
#       "tls.crt" = ""
#       }
#       depends_on = [helm_release.github_arc]
#     }

resource "kubernetes_manifest" "arc_managed_cert_staging" {
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
          "name" = "arc-webhook-server-ssl"
        }
        "solvers" = [{
          "http01" = {
            "ingress" = {
              "name" = "arc-webhook-ingress"
            }
          }
        }]
      }
    }
  }
  depends_on = [helm_release.cert_manager]
}


# resource "kubernetes_ingress_v1" "arc_ingress_stagning" {
#   metadata {
#     name      = "arc-webhook-ingress-staging"
#     namespace = "actions-runner-system"
#     annotations = {
#       "kubernetes.io/ingress.class"                 = "gce"
#       "kubernetes.io/ingress.global-static-ip-name" = "${var.arc_github_webhook_server_name}"
#       "cert-manager.io/issuer"                      = "arc-letsencrypt-staging"
#     }
#   }

#   #   spec {
#   #     backend {
#   #       service_name = "actions-runner-controller-github-webhook-server"
#   #       service_port = 80
#   #     }

#   spec {
#     rule {
#       http {
#         path {
#           backend {
#             service {
#               name = "actions-runner-controller-github-webhook-server"
#               port {
#                 number = 80
#               }
#             }
#           }
#           path = "/actions-runner-controller-github-webhook-server"
#         }
#       }
#     }
#     tls {
#       hosts       = ["wg-ci-test-arc-webhook-server.app-runtime-interfaces.ci.cloudfoundry.org"]
#       secret_name = "arc-webhook-server-ssl"
#     }
#   }
#   depends_on = [kubernetes_manifest.arc_managed_cert_staging]
# }





# resource "kubectl_manifest" "arc_ingress_staging" {
#     yaml_body = <<EOT
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: arc-webhook-ingress-staging
#   namespace: actions-runner-system
#   annotations:
#     kubernetes.io/ingress.class: gce
#     kubernetes.io/ingress.global-static-ip-name: wg-ci-test-arc-webhook-server
#     cert-manager.io/issuer: letsencrypt-staging
#     acme.cert-manager.io/http01-edit-in-place: "true"
# spec:
#   tls:
#   - hosts:
#     - wg-ci-test-arc-webhook-server.app-runtime-interfaces.ci.cloudfoundry.org
#     secretName: arc-webhook-server-ssl
#   rules:
#     - http:
#         paths:
#           - path: /actions-runner-controller-github-webhook-server
#             pathType: Prefix
#             backend:
#               service:
#                 name: actions-runner-controller-github-webhook-server
#                 port:
#                   number: 80
# EOT
# }

resource "kubectl_manifest" "arc_ingress_staging" {
    yaml_body = <<EOT
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: arc-webhook-ingress
  namespace: actions-runner-system
  annotations:
    kubernetes.io/ingress.allow-http: "true"
    kubernetes.io/ingress.class: gce
    kubernetes.io/ingress.global-static-ip-name: wg-ci-test-arc-webhook-server
    cert-manager.io/issuer: letsencrypt-staging
    acme.cert-manager.io/http01-edit-in-place: "true"
spec:
  tls:
  - hosts:
    - wg-ci-test-arc-webhook-server.app-runtime-interfaces.ci.cloudfoundry.org
    secretName: arc-webhook-server-ssl
  rules:
    - http:
        paths:
          - path: /actions-runner-controller-github-webhook-server
            pathType: Prefix
            backend:
              service:
                name: actions-runner-controller-github-webhook-server
                port:
                  number: 80
  defaultBackend:
    service:
      name: actions-runner-controller-github-webhook-server
      port:
        number: 80

EOT

depends_on = [kubernetes_manifest.arc_managed_cert_staging ]
}