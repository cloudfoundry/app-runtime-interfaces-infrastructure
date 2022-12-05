
# https://cert-manager.io/docs/tutorials/getting-started-with-cert-manager-on-google-kubernetes-engine-using-lets-encrypt-for-ingress-ssl/
# https://kosyfrances.com/ingress-gce-letsencrypt/
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_helm_version
  recreate_pods    = true

  set {
    name  = "installCRDs"
    value = true
  }
}


# resource "kubernetes_manifest" "letsencrypt_production" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "Issuer"
#     "metadata" = {
#       "name"      = "letsencrypt-production"
#       "namespace" = "actions-runner-system"
#     }
#     "spec" = {
#       "acme" = {
#         "server" = "https://acme-v02.api.letsencrypt.org/directory"
#         "email"  = "marcin.kubica@sap.com"
#         "privateKeySecretRef" = {
#           "name" = "letsencrypt-production"
#         }
#         "solvers" = [{
#           "http01" = {
#             "ingress" = {
#               "class" = "ingress-gce"
#             }
#           }
#         }]
#       }
#     }
#   }
#   depends_on = [helm_release.cert_manager]
# }


