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

# staging dns and recordset for letsencrypt - will provision only when var arc_letsencrypt_staging is set to true
resource "google_compute_global_address" "arc_webhook_server_staging" {
  count = "${var.arc_letsencrypt_staging ? 1 : 0}"
  project      = var.project
  address_type = "EXTERNAL"
  name = "${var.webhook_server_dns_staging}"
}

resource "google_dns_record_set" "arc_webhook_server_staging" {
  count = "${var.arc_letsencrypt_staging ? 1 : 0}"
  managed_zone = data.google_dns_managed_zone.dns.name
  name         = "${google_compute_global_address.arc_webhook_server_staging[0].name}.${data.google_dns_managed_zone.dns.dns_name}"
  type         = "A"
  rrdatas      = [google_compute_global_address.arc_webhook_server_staging[0].address]
  ttl          = 300
  project      = var.project
}
