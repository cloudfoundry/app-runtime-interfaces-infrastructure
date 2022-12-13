resource "google_service_account" "team_arc_node_pool" {
  account_id   = "${var.gke_name}-${var.team_name}-pool"
  display_name = "Service account for ${var.gke_name} GKE Github Actions Controller node pool"
  project      = var.project
}

resource "google_container_node_pool" "team_github_arc" {
  cluster    = data.google_container_cluster.wg_ci.name
  node_count = var.gke_arc_node_pool_count

  node_locations = [var.zone]
  project        = var.project
  location       = var.zone

  autoscaling {
    max_node_count       = var.gke_arc_node_pool_autoscaling_max
    min_node_count       = var.gke_arc_node_pool_count
    total_max_node_count = "0"
    total_min_node_count = "0"
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  max_pods_per_node = "110"
  name              = "${var.team_name}-arc-workers"

  node_config {
    disk_size_gb    = "${var.gke_arc_node_pool_disk_size_gb}"
    disk_type       = "pd-standard"
    image_type      = "COS_CONTAINERD"
    local_ssd_count = var.gke_arc_node_pool_ssd_count
    machine_type    = var.gke_arc_node_pool_machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/userinfo.email"]
    preemptible     = "false"
    service_account = google_service_account.team_arc_node_pool.email

    shielded_instance_config {
      enable_integrity_monitoring = "true"
      enable_secure_boot          = "false"
    }

    spot = "false"
    tags = ["${var.team_name}-arc-workers"]

    taint {
      effect = "NO_SCHEDULE"
      key    = "${var.team_name}-arc-workers"
      value  = "true"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }


  upgrade_settings {
    max_surge       = "1"
    max_unavailable = "0"
  }

  lifecycle {
    ignore_changes = all
  }
}

