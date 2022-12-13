terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    github = {
      source  = "integrations/github"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

data "google_client_config" "provider" {}

data "google_container_cluster" "wg_ci" {
  project  = var.project
  name     = var.gke_name
  location = var.zone
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.wg_ci.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.wg_ci.master_auth[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = "https://${data.google_container_cluster.wg_ci.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.wg_ci.master_auth[0].cluster_ca_certificate)

}

provider "github" {
  # please setup your GITHUB_TOKEN env var or will give an error:
  #   - Error: POST https://api.github.com/repos/... 404 Not Found
  #   - Also, upon removal of a webhook it will be silently gone from
  #     terraform state without an error

  # a work around the provider requiring an owner to be set in the provider definition
  # when ommited it would set the repo owner from user's private github token
  # failing to register webhook for an organisational repository as well as preventing
  # config based use of multiple repositories for different organisations
  owner = "./"
}

