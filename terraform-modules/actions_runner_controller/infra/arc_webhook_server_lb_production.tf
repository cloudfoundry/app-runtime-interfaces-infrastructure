resource "kubernetes_secret_v1" "arc_ingress_ssl_production" {
  count = var.arc_letsencrypt_production ? 1 : 0
  metadata {
    name      = "arc-ingress-production"
    namespace = "actions-runner-system"
  }

  type = "kubernetes.io/tls"
  data = {
    "tls.key" = ""
    "tls.crt" = ""
  }
  depends_on = [helm_release.github_arc]

  # create empty secret at first and ignore contents later as secret is updated by letsencrypt
  # NOTE: after the teardown please manually remove k8s secret actions-runner-system/arc-ingress-production if still present
  lifecycle {
    ignore_changes = all
  }
}


resource "kubectl_manifest" "arc_letsencrypt_production" {
  count      = var.arc_letsencrypt_production ? 1 : 0
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: arc-letsencrypt-production
  namespace: actions-runner-system
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: "${var.arc_letsencrypt_notifications_email}"
    privateKeySecretRef:
      name: arc-letsencrypt-production
    solvers:
    - http01:
        ingress:
          name: arc-webhook-server-production
       YAML
  depends_on = [helm_release.cert_manager]
}


locals {
  ingress_hostname_production = var.arc_letsencrypt_production ? trimsuffix("${google_dns_record_set.arc_webhook_server_production[0].name}", ".") : "none"
}

resource "kubectl_manifest" "arc_ingress_production" {
  count      = var.arc_letsencrypt_production ? 1 : 0
  yaml_body  = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: arc-webhook-server-production
  namespace: actions-runner-system
  annotations:
    kubernetes.io/ingress.allow-http: "true"
    kubernetes.io/ingress.class: gce
    kubernetes.io/ingress.global-static-ip-name: "${google_compute_global_address.arc_webhook_server_production[0].name}"
    cert-manager.io/issuer: arc-letsencrypt-production
spec:
  tls:
  - hosts:
    - "${local.ingress_hostname_production}"
    secretName: arc-ingress-production
  defaultBackend:
    service:
      name: actions-runner-controller-github-webhook-server
      port:
        number: 80
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
  YAML
  depends_on = [helm_release.cert_manager]
}
