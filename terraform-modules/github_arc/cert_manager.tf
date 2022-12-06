
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

  depends_on = [google_container_node_pool.github_arc]
    
 
}
