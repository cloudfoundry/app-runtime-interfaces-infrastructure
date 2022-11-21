resource "google_dns_managed_zone" "app_runtime_interfaces" {
  name        = "app-runtime-interfaces"
  dns_name    = "app-runtime-interfaces.ci.cloudfoundry.org."
  description = "app-runtime-interfaces WG DNS zone"
  visibility =  "public"
  dnssec_config {
    state = "off"
  }
}

# no recordsets are currently managed