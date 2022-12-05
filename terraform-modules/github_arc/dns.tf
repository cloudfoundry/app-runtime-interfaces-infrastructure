data "google_dns_managed_zone" "dns" {
  name    = var.dns_zone
  project = var.project
}


resource "google_compute_global_address" "arc_webhook_server_production" {
  project      = var.project
  address_type = "EXTERNAL"
  name = "${var.webhook_server_dns_production}"
}

resource "google_dns_record_set" "arc_webhook_server_production" {
  managed_zone = data.google_dns_managed_zone.dns.name
  name         = "${google_compute_global_address.arc_webhook_server_production.name}.${data.google_dns_managed_zone.dns.dns_name}"
  type         = "A"
  rrdatas      = [google_compute_global_address.arc_webhook_server_production.address]
  ttl          = 300
  project      = var.project
}


# records which can be used to develop/test staging loadbalancer with letsencrypt staging certs
# please comment out once done to remove from cloud

resource "google_compute_global_address" "arc_webhook_server_staging" {
  project      = var.project
  address_type = "EXTERNAL"
  name = "${var.webhook_server_dns_staging}"
}

resource "google_dns_record_set" "arc_webhook_server_staging" {
  managed_zone = data.google_dns_managed_zone.dns.name
  name         = "${google_compute_global_address.arc_webhook_server_staging.name}.${data.google_dns_managed_zone.dns.dns_name}"
  type         = "A"
  rrdatas      = [google_compute_global_address.arc_webhook_server_staging.address]
  ttl          = 300
  project      = var.project
}