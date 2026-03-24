resource "google_sql_database" "concourse" {
  for_each = toset([
    "concourse",
    "credhub",
    "uaa"
  ])
  charset   = "UTF8"
  collation = "en_US.UTF8"
  # The SQL instance is created by the infra stack; use its configured name directly.
  instance   = var.sql_instance_name
  name       = each.key
  project    = var.project
  depends_on = [carvel_kapp.sqlproxy, carvel_kapp.carvel_secretgen]
}

