resource "google_sql_database_instance" "concourse" {
  database_version = var.database_version
  name             = var.sql_instance_name
  project          = var.project
  region           = var.region

  # This option prevents Terraform from deleting an instance
  deletion_protection = var.db_terraform_deletion_protection

  settings {
    activation_policy = "ALWAYS"
    availability_type = "REGIONAL"

    backup_configuration {

      location = var.sql_instance_backup_location
      backup_retention_settings {
        retained_backups = "7"
        retention_unit   = "COUNT"
      }

      binary_log_enabled             = "false"
      enabled                        = "true"
      point_in_time_recovery_enabled = "true"
      start_time                     = "00:00"
      transaction_log_retention_days = "7"
    }

    deletion_protection_enabled = var.db_engine_level_deletion_protection

    disk_autoresize       = "true"
    disk_autoresize_limit = "0"
    disk_size             = var.sql_instance_disk_size
    disk_type             = "PD_SSD"

    edition = "ENTERPRISE"

    ip_configuration {
      ipv4_enabled = "true"
    }

    location_preference {
      zone           = var.zone
      secondary_zone = var.sql_instance_secondary_zone
    }

    maintenance_window {
      day          = 7 #Sunday
      hour         = 0 #0:00 - 1:00 hours
      update_track = "stable"
    }

    pricing_plan = "PER_USE"
    tier         = var.sql_instance_tier

  }
}

