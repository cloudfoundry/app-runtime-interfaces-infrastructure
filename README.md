# App Runtime Interfaces - Concourse on GCP Kubernetes

## Background

Based on [cloudfoundry/bosh-community-stemcell-ci-infra](https://github.com/cloudfoundry/bosh-community-stemcell-ci-infra)

## Introduction

This repository contains infrastructure as code for the App Runtime Interfaces Working Group.
It deploys from scratch everything needed for a Concourse deployment running on Kubernetes on GCP and supports day 2 operations like testing updates, disaster recovery and credentials rotation using Terraform and Terragrunt.

You may [watch an introductory video](docs/short_introduction.mp4) to this project and how you can use it to set up your own Concourse.

## Architecture

![editable drawio png bitmap](./docs/concourse-architecture.drawio.svg)
### Requirements

#### Required tools

We use [asdf](https://asdf-vm.com/) with versions [.tool-versions](./.tool-versions) file
* glcoud
* helm
* terraform
* terragrunt
* kapp
* ytt
* vendir
* yq

Install asdf then execute [./terragrunt/scripts/asdf-plugin-install.sh](./terragrunt/scritps/asdf-plugin-install.sh)
#### Permissions

Users who are required to perform operations need to be added in the Role `WG CI Manage` via IAM in the Google Cloud console.

## Prerequisites for a fresh project

### 1. Configuration

To consume the project with our terragrunt code and scripts please create a folder structure in your project with a copy of

* `terragrunt/scripts`
* `terragrunt/concourse-<gke_name>`
* `.tools-versions`

* Use `git resource` for terraform modules: see [terragrunt/concourse-wg-ci-test/config.yaml](./terragrunt/concourse-wg-ci-test/config.yaml) or
copy `terraform-modules` folder to your repository, see [terragrunt/concourse-wg-ci/config.yaml](./terragrunt/concourse-wg-ci/config.yaml)

#### Adjust `config.yml`

You should at least look at the following variables:

* `project / region / zone / secondary_zone`
* `gcs_bucket`
* `dns_record / dns_zone / dns_domain`
* `gke_name`
* `concourse_github_mainTeam`


#### 2. Logon to your GCP account
```
gcloud auth login && gcloud auth application-default login
```

#### 3. Create Github OAuth App and supply as a Google Secret

This is necessary if you want to be able to authenticate with your GitHub profile.
 1. Create Github OAuth App

    Log on to github.com https://github.com/settings/developers -> Click "New OAuth App"

    As "Homepage URL", enter the Concourse's base URL beginning with **https://**.

    As "Authorization callback URL", enter the Concourse URL followed by `/sky/issuer/`callback` also beginning with **https**://**.


 2. Create Google Secret

    Open [scripts/create-github-oauth-gcp.sh](scripts/create-github-oauth-gcp.sh) and enter you credetials for **id** and **secret**.

    Run
    ```
    cd <folder with config.yaml>
    ../scripts/create-github-oauth-gcp.sh
    ```
 For more information please refer to [gcloud documentation](https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets).
#### 4. Apply terrgrunt for the entire stack

The following command needs to be run from within your root directory (containing `config.yaml` file).

*NOTE: it's not possible to `plan` for a fresh project due to the fact we can't test kubernetes resources against non-existing cluster*

*NOTE: `terragrunt run-all` commands **do not** show changes before applying*

```sh
terragrunt run-all apply
```

## Recommendations
### Cloud SQL Instance deletion protection

Terraform hashicorp provider includes a deletion protection flag however in some cases it's misleading as it's not setting it on Google Cloud.
To avoid confusion we do not set it in the code and recommend altering your production SQL Instance to protect from the deletion on the cloud side.

https://console.cloud.google.com/sql/instances/ -> select instance name -> edit ->  Data Protection -> tick: Enable delete protection

### End-to-end testing

Please see [end to end testing](./docs/end_to_end_testing.md)
### Developer notes
Please see [developer notes](docs/developer_notes.md) about `vendir sync` and developing modules with `terragrunt`.

## Notes and known limitations


### Destroy the project
If you have manually set the recommeded ClouSQL instane deletion protection please unset it.


Since we protect a backup of credhub encryption key (stored in GCP Secret Manager) to fully destroy the project it needs to be removed from terraform state first.

```
cd <folder with config.yaml>/dr_create

terragrunt state rm google_secret_manager_secret_version.credhub_encryption_key
terragrunt state rm google_secret_manager_secret.credhub_encryption_key
```

**WARNING: to complete deletion, remove the secret from GCP Secret manager -- please be aware doing so will _permantently_ prevent DR recovery**

```
gcloud secrets delete <gke_name>-credhub-encryption-key --project=<your project name>
```

To destroy:
```
terragrunt run-all destroy
```

Delete terraform state gcp bucket from GCP console or via `gsutil`

### Carvel kapp terraform provider not available for Apple M1
https://github.com/vmware-tanzu/terraform-provider-carvel/issues/30#issuecomment-1311465417

### Plan/apply terragrunt for a specific component of the stack

```sh
cd concourse/app
terragrunt plan
terragrunt apply
```



### How to obtain GKE credentials for your terminal
Terraform code is fetching GKE credentials automatically. In case you need to access the cluster with `kubectl` (or other kube clients) or to connect to Credhub instance (via `terragrunt/scripts/start-credhub-cli.sh`)

```sh
gcloud container clusters list
# Example output:
# NAME   LOCATION        MASTER_VERSION   MASTER_IP     MACHINE_TYPE   NODE_VERSION     NUM_NODES  STATUS
# wg-ci  europe-west3-a  1.23.8-gke.1900  34.159.31.85  e2-standard-4  1.23.8-gke.1900  3          RUNNING

gcloud container clusters get-credentials wg-ci --zone europe-west3-a
# Example output:
# Fetching cluster endpoint and auth data.
# kubeconfig entry generated for wg-ci.

kubectl config current-context
# Example output:
# gke_app-runtime-interfaces-wg_europe-west3-a_wg-ci
```

## DR scenario
Please see [DR scenario](docs/disaster_recovery.md) for a fully automated recovery procedure.


## Automated secrets rotation for CloudSQL
Please see [Secrets Rotation](docs/secrets_rotation.md)
