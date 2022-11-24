resource "google_compute_firewall" "arc_webhook" {
  name    = "gke-${var.gke_name}-github-arc-webhook"
  network = data.google_container_cluster.wg_ci.network

  allow {
    protocol = "tcp"
    ports    = ["9443"]
  }

  direction = "INGRESS"

  source_ranges = [data.google_container_cluster.wg_ci.private_cluster_config[0].master_ipv4_cidr_block]
  }

