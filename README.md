# App Runtime Interfaces Infrastructure

## Introduction

This repository contains infrastructure as code for the App Runtime Interfaces Working Group.
It deploys from scratch everything needed for deployments running on Kubernetes on GCP and supports day 2 operations like testing updates, disaster recovery and credentials rotation using Terraform and Terragrunt.

Terraform modules can be consumed externally via git sourcing and git tags.


## Available projects

### Concourse

Please see [Concourse Readme](./docs/concourse/README.md)

### Github Actions Runner Controller

Please see [ARC Readme](./docs/actions-runner-controller/README.md)

## Required tools

We use [asdf](https://asdf-vm.com/) with versions [.tool-versions](./.tool-versions) file
* glcoud
* helm
* terraform
* terragrunt
* kapp
* ytt
* vendir
* yq
* kubectl

Install asdf then execute [./asdf-plugin-install.sh](./asdf-plugin-install.sh)

Follow the readmes for a particular project.

