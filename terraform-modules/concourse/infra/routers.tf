resource "google_compute_router" "nat_router" {
  encrypted_interconnect_router = "false"
  name                          = "nat-router-${var.gke_name}"
  network                       = google_compute_network.vpc.name
  project                       = var.project
  region                        = var.region
}

resource "google_compute_address" "static_nat_ip" {
  count        = var.gke_use_static_nat_ips ? 2 : 0
  name         = "nat-ip-${count.index}"
  network_tier = "PREMIUM"
  region       = var.region
}

resource "google_compute_router_nat" "nat_config" {
  name                               = "nat-config-${var.gke_name}"
  project                            = var.project
  router                             = google_compute_router.nat_router.name
  region                             = google_compute_router.nat_router.region
  nat_ip_allocate_option             = var.gke_use_static_nat_ips ? "MANUAL_ONLY" : "AUTO_ONLY"
  nat_ips                            = var.gke_use_static_nat_ips ? google_compute_address.static_nat_ip.*.self_link : null
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  enable_dynamic_port_allocation      = false
  min_ports_per_vm = var.gke_cloud_nat_min_ports_per_vm

  enable_endpoint_independent_mapping = false
  tcp_established_idle_timeout_sec    = 180

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_compute_router.nat_router]
}