# App Runtime Interfaces - Concourse on GCP Kubernetes

## Background
Based on [cloudfoundry/bosh-community-stemcell-ci-infra](<https://github.com/cloudfoundry/bosh-community-stemcell-ci-infra>)

## Introduction
Terraform modules and terragrunt code for Concourse deployment running on Kubernetes on GCP.

You may [watch an introductory video](<short_introduction.mp4>) to this project and how you can use it to set up Concourse on your infrastructure.

## Architecture

![editable drawio svg bitmap](<concourse-architecture.drawio.svg>)
### Requirements

#### Permissions
Users who are required to perform operations need to be added in the Role `WG CI Manage` via IAM in the Google Cloud console.

## Prerequisites for a fresh project

### 1. Configuration
To consume the project with our terragrunt code and scripts please create a folder structure in your project with a copy of

* `terragrunt/scripts`
* `terragrunt/concourse-<gke_name>`
* `.tools-versions`

* Use `git resource` for terraform modules: see [terragrunt/concourse-wg-ci-test/config.yaml](<../../terragrunt/concourse-wg-ci-test/config.yaml>) or
copy `terraform-modules` folder to your repository, see [terragrunt/concourse-wg-ci/config.yaml](<../../terragrunt/concourse-wg-ci/config.yaml>)

⚠️ If you reference terraform modules with a tagged git revision, make sure to use the same tagged revision of `.tools-versions`. Otherwise, there will be version mismatch errors when you run terragrunt. Alternatively, make use of the file `flake.nix` via `nix develop` or via direnv-load, see: [direnv documentation](<https://direnv.net/man/direnv-stdlib.1.html#codeuse-flake-ltinstallablegtcode>)

Also make sure that your git ssh setup is working: [https://docs.github.com/en/authentication/connecting-to-github-with-ssh]. The referencing git URLs use ssh, not https.

#### Provide DNS Zone

The project does not automatically create a DNS zone. Either create one manually, or reuse an existing zone.

#### Adjust `config.yml`

You should at least look at the following variables:

* `project / region / zone / secondary_zone`
* `gcs_bucket`
* `dns_record / dns_zone / dns_domain`
* `gke_name`
* `concourse_github_mainTeam`

Also make sure that the GKE version is not outdated:

* `gke_controlplane_version`

The latest stable version can be found at [https://cloud.google.com/kubernetes-engine/docs/release-notes]

#### 2. Logon to your GCP account
```
gcloud auth login && gcloud auth application-default login
```

When using asdf instead of Nix, there can be problems with the "gke-gcloud-auth-plugin" if you use asdf as CLI management tool. If the "gcloud" CLI cannot find the plugin, you can copy the plugin into the `shims` folder as workaround:
```
cp ~/.asdf/installs/gcloud/415.0.0/bin/gke-gcloud-auth-plugin ~/.asdf/shims
```

To set the correct project out of the ones that you have access to (see `gcloud projects list`), run `gcloud config set project 'app-runtime-interfaces-wg'`.

#### 3. Create Github OAuth App and supply as a Google Secret

This is necessary if you want to be able to authenticate with your GitHub profile.
 1. Create Github OAuth App

    Log on to github.com <https://github.com/settings/developers> -> Click "New OAuth App"

    As "Homepage URL", enter the Concourse's base URL beginning with **https://**.

    As "Authorization callback URL", enter the Concourse URL followed by `/sky/issuer/`callback` also beginning with **https**://**.


 2. Create Google Secret

    Open [terragrunt/scripts/concourse/create-github-oauth-gcp.sh](../../terragrunt/scripts/concourse/create-github-oauth-gcp.sh) and enter your credentials for **id**** and **secret**.

    Run
    ```
    cd <folder with config.yaml>
    ../scripts/create-github-oauth-gcp.sh
    ```
 For more information please refer to [gcloud documentation](https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets).
#### 4. Apply terragrunt for the entire stack

The following command needs to be run from within your root directory (containing `config.yaml` file).

*NOTE: it's not possible to `plan` for a fresh project due to the fact we can't test kubernetes resources against non-existing cluster*

*NOTE: `terragrunt run-all` commands **do not** show changes before applying*

```sh
terragrunt run-all apply
```

*NOTE: Make sure that your Terragrunt TFPATH points to the "terraform" CLI and not to the "tofu" CLI. Tofu uses a different versioning scheme and may fail to load some plugins that check for a specific Terraform version:
```sh
export TERRAGRUNT_TFPATH=/Users/<your user id>/.asdf/shims/terraform
```

#### 5. Configure your local kubectl afterwards
  1. Login into the google cloud via `gcloud auth login && gcloud auth application-default login`.
  2. Configure you kubectl, see section [How to obtain GKE credentials for your terminal](<#how-to-obtain-gke-credentials-for-your-terminal>).

## Recommendations
### Cloud SQL Instance deletion protection

Terraform hashicorp provider includes a deletion protection flag however in some cases it's misleading as it's not setting it on Google Cloud.
To avoid confusion we do not set it in the code and recommend altering your production SQL Instance to protect from the deletion on the cloud side.

https://console.cloud.google.com/sql/instances/ -> select instance name -> edit ->  Data Protection -> tick: Enable delete protection

### End-to-end testing

Please see [end to end testing](end_to_end_testing.md)
### Developer notes
Please see [developer notes](developer_notes.md) about `vendir sync` and developing modules with `terragrunt`.

## Notes and known limitations

### x509: certificate has expired or is not yet valid
Credhub credentials are expired if they are older than 30 days. As a result, following error messages are occurs
 - Credhub pod:  `Get "https://credhub.concourse.svc.cluster.local:9000/info": x509: certificate has expired or is not yet valid: current time 2023-02-27T10:14:45Z is after 2023-02-25T15:05:44Z`
 - Concourse input resources `x509: certificate has expired or is not yet valid`

Solution

Restart the credhub kubernetes deployment in the concourse namespace. It will destroy the old pod and create a new one.
> This is workaround. The bug is describe [issues#61](<https://github.com/cloudfoundry/app-runtime-interfaces-infrastructure/issues/61>)

#### Details

From the Cloud Console:
1. Go to [Google Cloud Console](<https://console.cloud.google.com/kubernetes/deployment/europe-west3-a/wg-ci/concourse/credhub/overview?project=app-runtime-interfaces-wg>)
2. Go to managed pods and delete the pods

From local:
  1. Clone this project and either use nix or asdf to set up you environment.
  2. Login into the google cloud via `gcloud auth login && gcloud auth application-default login`.
  3. Configure you kubectl, see section [How to obtain GKE credentials for your terminal](<#how-to-obtain-gke-credentials-for-your-terminal>).
  4. Execute `kubectl delete pods --namespace='concourse' --selector='app=credhub'`.

### x509: certificate has expired or is not yet valid: CA edition

If the above solution did not help, it might also be the CA that expires once a year.

Check its age

```shell
kubectl get secret -n concourse credhub-root-ca
```

If it is older than a year, delete it:

```shell
kubectl delete secret -n concourse credhub-root-ca
```

Afterwards restart the secretgen-controller to trigger a recreation:

```shell
kubectl scale deploy -n secretgen-controller secretgen-controller --replicas=0
kubectl scale deploy -n secretgen-controller secretgen-controller --replicas=1
kubectl wait deployment -n secretgen-controller secretgen-controller --for=jsonpath='{.spec.replicas}'=1 --timeout=30s
```

Check that the CA has been recreated:

```shell
kubectl get secret -n concourse credhub-root-ca
```

Restart credhub and concourse:

```shell
kubectl delete pods --namespace='concourse' --selector='app=credhub'
kubectl delete pods --namespace='concourse' --selector='release=concourse'
```

### Destroy the project
If you have manually set the recommended CloudSQL instance deletion protection please unset it.


Since we protect a backup of CredHub encryption key (stored in GCP Secret Manager) to fully destroy the project it needs to be removed from terraform state first.

```
cd <folder with config.yaml>/dr_create

terragrunt state rm google_secret_manager_secret_version.credhub_encryption_key
terragrunt state rm google_secret_manager_secret.credhub_encryption_key
```

**WARNING: to complete deletion, remove the secret from GCP Secret manager -- please be aware doing so will _permanently_ prevent DR recovery**

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

To compile the provider locally, clone the repository https://github.com/carvel-dev/terraform-provider and run:
```
go mod tidy
go build -o terraform-provider-carvel ./cmd/main.go
```
Then copy the binary into the local Terraform "plugins" folder:
```
cp ./terraform-provider-carvel ~/.terraform.d/plugins/registry.terraform.io/vmware-tanzu/carvel/0.11.0/darwin_arm64
```
In case of Terraform checksum mismatches, go to a Terraform module and run "terraform init" to fix the checksums.

### Plan/apply terragrunt for a specific component of the stack

```sh
cd terragrunt/concourse-<gke_name>/concourse/app
terragrunt plan
terragrunt apply
```



### How to obtain GKE credentials for your terminal
Terraform code is fetching GKE credentials automatically. In case you need to access the cluster with `kubectl` (or other kube clients) or to connect to Credhub instance (via `terragrunt/scripts/concourse/start-credhub-cli.sh`)

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
Please see [DR scenario](disaster_recovery.md) for a fully automated recovery procedure.


## Automated secrets rotation for CloudSQL
Please see [Secrets Rotation](secrets_rotation.md)

## Automated regeneration for certificates stored in CredHub
Please see [Certificate Regeneration](certificate_regeneration.md)