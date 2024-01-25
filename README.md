# App Runtime Interfaces Infrastructure

## Introduction
This repository contains infrastructure as code for the App Runtime Interfaces Working Group.
It deploys from scratch everything needed for deployments running on Kubernetes on GCP and supports day 2 operations like testing updates, disaster recovery and credentials rotation using Terraform and Terragrunt.

Terraform modules can be consumed externally via git sourcing and git tags.

## Available projects

### Concourse
Please see [Concourse Readme](<./docs/concourse/README.md>)

### Github Actions Runner Controller
Please see [ARC Readme](<./docs/actions-runner-controller/README.md>)

## Required tools
The required tools to work with this repository are:
  * glcoud
  * helm
  * opentofu
  * terragrunt
  * kapp
  * ytt
  * vendir
  * yq
  * kubectl

They can be loaded with the [Nix](<https://nixos.org>) package manager via this repository's file “flake.nix”-file or – using [asdf](<https://asdf-vm.com>) – via this repository's file “.tool-versions”. To make use of the ladder you may need to execute [./asdf-plugin-install.sh](<./asdf-plugin-install.sh>) after the installation of asdf. We generally recommend to use direnv which triggers either nix (preferably) or asdf via the file “.envrc” in this repository.

Follow the readmes for a particular project.