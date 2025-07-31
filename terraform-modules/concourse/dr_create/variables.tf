variable "project" { nullable = false }
variable "region" { nullable = false }
variable "zone" { nullable = false }

variable "gke_name" { nullable = false }

variable "credhub_secret_prevent_destroy" {
  description = "Prevent deletion of credhub encryption key secret version"
  type        = bool
  default     = true
  nullable    = false
}
