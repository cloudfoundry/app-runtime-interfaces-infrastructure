variable "project" { nullable = false }
variable "region" { nullable = false }
variable "zone" { nullable = false }

variable "gke_name" { nullable = false }
variable "github_arc_workers_pool_machine_type" { nullable = false }
variable "github_arc_workers_pool_node_count" { nullable = false }
variable "github_arc_workers_pool_autoscaling_max" { nullable = false }
variable "github_arc_workers_pool_ssd_count" { nullable = false }

variable "cert_manager_helm_version" { nullable = false }
variable "github_arc_helm_version" { nullable = false }

variable "arc_github_access_token_name" { nullable = false }
variable "arc_github_webhook_server_name" { nullable = false }
variable "arc_github_webhook_server_token_name" { nullable = false }

variable "arc_storage_type" { nullable = false }

variable "arc_letsencrypt_staging" { nullable = false }

variable "webhook_server_dns_production" { nullable = false }
variable "webhook_server_dns_staging" { nullable = false }
variable "dns_zone" { nullable = false }
variable "dns_domain" { nullable = false }

