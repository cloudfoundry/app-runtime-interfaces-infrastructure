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

      #create empty secret at first and ignore contents later as secret is updated by ingress
      lifecycle {
        ignore_changes = all
      }
    }


resource "kubernetes_secret_v1" "arc_ingress_ssl_production" {
    metadata {
      name = "arc-ingress-production"
      namespace = "actions-runner-system"
      }

    type = "kubernetes.io/tls"
    data = {
      "tls.key" = ""
      "tls.crt" = ""
      }
      depends_on = [helm_release.github_arc]

      #create empty secret at first and ignore contents later as secret is updated by ingress
      lifecycle {
        ignore_changes = all
      }
    }


# resource "kubectl_manifest" "arc_ingress" {
#     yaml_body = <<EOT
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: arc-webhook-ingress
#   namespace: actions-runner-system
#   annotations:
#     kubernetes.io/ingress.allow-http: "false"
#     kubernetes.io/ingress.class: gce
#     kubernetes.io/ingress.global-static-ip-name: wg-ci-test-arc
#     cert-manager.io/issuer: letsencrypt-production
# spec:
#   tls:
#   - hosts:
#     - wg-ci-test-arc.app-runtime-interfaces.ci.cloudfoundry.org
#     secretName: arc-ingress-ssl-production
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
#   defaultBackend:
#     service:
#       name: actions-runner-controller-github-webhook-server
#       port:
#         number: 80

# EOT
# depends_on = [kubernetes_manifest.letsencrypt_production, kubernetes_secret_v1.arc_ingress_ssl ]
# }

# resource "kubernetes_ingress_v1" "arc_ingress_staging" {
#   metadata {
#     name      = "arc-webhook-ingress-staging"
#     namespace = "actions-runner-system"
#     annotations = {
#       "kubernetes.io/ingress.allow-http"            = "true"
#       "kubernetes.io/ingress.class"                 = "gce"
#       "kubernetes.io/ingress.global-static-ip-name" = "${google_compute_global_address.arc_webhook_server_staging.name}"
#     #  "cert-manager.io/issuer"                      = "letsencrypt-staging"
#     }
#   }
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
#           path_type = "Prefix"
#         }
#       }
#     }
#     tls {
#       hosts       = [ trimsuffix("${google_dns_record_set.arc_webhook_server_staging.name}", ".")]
#       secret_name = "arc-ingress-ssl-staging"
#     }
#     default_backend {
#         service {
#           name = "actions-runner-controller-github-webhook-server"
#           port {
#             number = 80
#           }
#         }
#     }
#   }
#   depends_on = [
#     kubernetes_manifest.letsencrypt_staging,
#     kubernetes_secret_v1.arc_ingress_ssl_staging,
#     google_dns_record_set.arc_webhook_server_staging
#      ]
#
# }


resource "kubectl_manifest" "arc_ingress_staging" {
    yaml_body = <<EOT
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: arc-staging
  namespace: actions-runner-system
  annotations:
    #kubernetes.io/ingress.allow-http: "true"
    kubernetes.io/ingress.class: gce
    kubernetes.io/ingress.global-static-ip-name: wg-ci-test-arc-s
    cert-manager.io/issuer: arc-letsencrypt-staging
spec:
  tls:
  - hosts:
    - wg-ci-test-arc-s.app-runtime-interfaces.ci.cloudfoundry.org
    secretName: arc-ingress-staging
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
  depends_on = [
    kubernetes_manifest.letsencrypt_staging,
    kubernetes_secret_v1.arc_ingress_ssl_staging,
    google_dns_record_set.arc_webhook_server_staging
     ]

}
