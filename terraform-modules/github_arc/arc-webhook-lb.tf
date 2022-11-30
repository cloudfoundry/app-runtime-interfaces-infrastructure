# resource "google_project_service" "apis" {
#   service            = "certificatemanager.googleapis.com"
#   project            = var.project
#   disable_on_destroy = false
#   depends_on = [google_dns_record_set.arc_webhook_server]

# }

# resource "google_compute_managed_ssl_certificate" "arc_webhook_server" {
#   name = "${var.gke_name}-arc-webhook-server"

#   managed {
#     domains = [ google_dns_record_set.arc_webhook_server.name ]
#   }
#   depends_on = [google_project_service.apis]
# }



# resource "kubernetes_manifest" "arc_managed_cert" {
#     manifest = {
#         "apiVersion" = "networking.gke.io/v1"
#         "kind"       = "ManagedCertificate"
#         "metadata" = {
#             "name" =  "arc-managed-cert"
#             }
#          "spec" = {
#            "domains" = [
#             "${var.dns_record}.${var.dns_zone}.${var.dns_domain}"
#             ]
#            }
#     }
# depends_on = [google_project_service.apis]

# }

# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: arc-webhook-ingress
#   namespace: actions-runner-system
#   annotations:
#     # This tells Google Cloud to create an External Load Balancer to realize this Ingress
#     kubernetes.io/ingress.class: gce
#     # This tells Google Cloud to associate the External Load Balancer with the static IP which we created earlier
#     kubernetes.io/ingress.global-static-ip-name: web-ip
#     cert-manager.io/issuer: letsencrypt-staging
# spec:
#   tls:
#     - secretName: "${kubernetes_secret_v1.arc_letsencrypt_secret.metadata[0].name}"
#   defaultBackend:
#     service:
#       name: actions-runner-controller-github-webhook-server
#       port:
#         number: 80