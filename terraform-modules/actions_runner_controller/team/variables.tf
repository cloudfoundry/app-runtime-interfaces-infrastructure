variable "project" { nullable = false }
variable "region" { nullable = false }
variable "zone" { nullable = false }

variable "team_name" { nullable = false }

variable "gke_name" { nullable = false }
variable "gke_arc_node_pool_disk_size_gb" { nullable = false }
variable "gke_arc_node_pool_machine_type" { nullable = false }
variable "gke_arc_node_pool_count" { nullable = false }
variable "gke_arc_node_pool_autoscaling_max" { nullable = false }
variable "gke_arc_node_pool_ssd_count" { nullable = false }
variable "gke_arc_runner_storage_type" { nullable = false }

variable "arc_github_webhook_server_token_name" { nullable = false }
variable "arc_webhook_server_production_domain" { nullable = false }
variable "arc_github_webhook_server_name" { nullable = false }

variable "github_repos" {
  type = list(object({
    name = string
    owner = string
    hpa_scaleup_trigger_duration = string
    hpa_scaledown_delay_seconds = number
    runnerset_resource_request_cpu = string
    runnerset_resource_request_mem = string
    runnerset_resource_limits_cpu = string
    runnerset_resource_limits_mem = string
    var_lib_docker_size = string
  }))
}

