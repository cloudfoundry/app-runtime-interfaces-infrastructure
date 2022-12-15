variable "project" { nullable = false }
variable "region" { nullable = false }
variable "zone" { nullable = false }

variable "gke_name" { nullable = false }

variable "cert_manager_helm_version" { nullable = false }
variable "arc_helm_version" { nullable = false }

variable "arc_github_access_token_name" { nullable = false }
variable "arc_github_webhook_server_name" { nullable = false }
variable "arc_github_webhook_server_token_name" { nullable = false }

variable "arc_letsencrypt_staging" { nullable = false }
variable "arc_letsencrypt_production" { nullable = false }
variable "arc_letsencrypt_notifications_email" { nullable = false }

variable "webhook_server_dns_production" { nullable = false }
variable "webhook_server_dns_staging" { nullable = false }
variable "dns_zone" { nullable = false }
variable "dns_domain" { nullable = false }
