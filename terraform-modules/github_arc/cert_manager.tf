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
