# Staging configuration for lentsencrypt and dns - not required for daily use
# Set var arc_letsencrypt_staging to true (bool) to enable. Please disable if not needed (dev use only)
resource "kubernetes_secret_v1" "arc_ingress_ssl_staging" {
  count =  "${var.arc_letsencrypt_staging ? 1 : 0}"
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

      # create empty secret at first and ignore contents later as secret is updated by letsencrypt
      # NOTE: after the teardown please manually remove k8s secret actions-runner-system/arc-ingress-staging if stil present
      lifecycle {
        ignore_changes = all
      }
    }


resource "kubectl_manifest" "arc_letsencrypt_staging" {
   count = "${var.arc_letsencrypt_staging ? 1 : 0}"
   yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: arc-letsencrypt-staging
  namespace: actions-runner-system
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: "A${var.arc_letsencrypt_notifications_email}"
    privateKeySecretRef:
      name: arc-letsencrypt-staging
    solvers:
    - http01:
        ingress:
          name: arc-webhook-ingress-staging
       YAML
       depends_on = [helm_release.cert_manager]
}

locals {
 # work around teardown problem when var arc_letsencrypt_staging is set to false
 ingress_hostname_staging = "${var.arc_letsencrypt_staging ? trimsuffix("${google_dns_record_set.arc_webhook_server_staging[0].name}", ".") : "none"}"
 }

resource "kubectl_manifest" "arc_ingress_staging" {
  count = "${var.arc_letsencrypt_staging ? 1 : 0}"
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: arc-webhook-ingress-staging
  namespace: actions-runner-system
  annotations:
    kubernetes.io/ingress.allow-http: "true"
    kubernetes.io/ingress.class: gce
    kubernetes.io/ingress.global-static-ip-name: "${google_compute_global_address.arc_webhook_server_staging[0].name}"
    cert-manager.io/issuer: arc-letsencrypt-staging
spec:
  tls:
  - hosts:
    - "${local.ingress_hostname_staging}"
    secretName: arc-ingress-staging
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
