data "google_dns_managed_zone" "dns" {
  name    = var.dns_zone
  project = var.project
}


resource "google_compute_global_address" "arc_webhook_server" {
  project      = var.project
  address_type = "EXTERNAL"
  # gcp ip addres name can't contain dots
  name = var.arc_github_webhook_server_name
}

resource "google_dns_record_set" "arc_webhook_server" {
  managed_zone = data.google_dns_managed_zone.dns.name
  name         = "${var.dns_record}.${data.google_dns_managed_zone.dns.dns_name}"
  type         = "A"
  rrdatas      = [google_compute_global_address.arc_webhook_server.address]
  ttl          = 300
  project      = var.project
}
