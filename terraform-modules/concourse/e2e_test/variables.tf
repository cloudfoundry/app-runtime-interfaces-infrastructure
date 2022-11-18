variable "credhub-test-secret-prefix" {
  default = "credhub-cli-tf"
}

variable "credhub-test-secret-path" { nullable = false }

variable "fly_target" { nullable = false }
variable "fly_team" { nullable = false }

variable "pipeline"  { nullable = false }
variable "pipeline_job"  { nullable = false }

# expose e2e pipeline
variable "pipeline_exposed" { 
  default = true 
  }

variable "project" { nullable = false }
variable "region" { nullable = false }
variable "zone" { nullable = false }

variable "gke_name" { nullable = false }