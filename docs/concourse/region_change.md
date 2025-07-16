# Region Migration Guide
For cost saving reasons, you can migrate the Concourse deployment to a different region. This guide will help you restore the Concourse deployment in a new region using the existing configuration.

## Prerequisites
- Access to the GCP account and the GKE cluster in the current region.
- You have the "Owner" role in the GCP project ("Editor" is not sufficient).
- "pg_dump" v16 is installed on the local machine.

## Backup Secrets and Databases
1. Logon to the GCP account and the GKE cluster in the current region.
1. In the GCP Secret Manager, retrieve and save the following credentials as a backup:
   - `wg-ci[-test]-credhub-encryption-key`
   - `wg-ci[-test]-concourse-github-oauth`

   You can also use the following command to retrieve the secrets:
   ```bash
   gcloud secrets versions access latest --secret=<secret-name>
   ```
1. Install and start the Cloud SQL Auth Proxy as documented here: https://cloud.google.com/sql/docs/postgres/connect-instance-auth-proxy
1. The "concourse" database which contains the pipelines must be backed up. Retrieve the password:
   ```bash
   kubectl -n concourse get secret concourse-postgresql-password -o yaml | yq -r .data.password | base64 -d
   ```
1. Dump the database content using the `pg_dump` command:
   ```bash
   pg_dump "postgresql://concourse@localhost:5432/concourse" > "concourse_backup.sql"
   ```
1. The "credhub" database is encrypted with a key. Migration of the encryption key is not easily possible because upon re-creation, a new key is automatically generated and applied. So we use the CredHub CLI to export the CredHub data. Log on to CredHub with the [start-credhub-cli.sh](../../terragrunt/scripts/concourse/start-credhub-cli.sh) script. Then export all data:
   ```bash
   credhub export --output-file=credhub_backup.json
   ```
   Copy the file from the pod to the local machine:
   ```bash
   kubectl -n default cp credhub-cli-<id>:/go/credhub_backup.json credhub_backup.json
   ```
   :warning: The file `credhub_backup.json` contains sensitive data in plaintext, so handle it with care and delete it after the migration.

## Destroy the Current Concourse Deployment
1. Open file `terraform-modules/concourse/dr_create/credhub_encryption_key.tf`.
1.1 In resource "google_secret_manager_secret_version", comment the "lifecycle" block (to disable `prevent_destroy = true`).
1.1 Comment module "assertion_encryption_key_identical" (if you receive `Error: Unsupported OpenTofu Core version`).
1. In `terraform-modules/concourse/infra/database.tf`, set `deletion_protection` and `deletion_protection_enabled` to `false`.
1. In `terraform-modules/concourse/infra/gke_cluster.tf` add `deletion_protection = false` (the default is `true`).
1. Go to folder `terragrunt/concourse-wg-ci[-test]/infra` and run `terragrunt apply`. This updates the deletion protection settings for the Cloud SQL database and the GKE cluster.
1. Go to folder `terragrunt/concourse-wg-ci[-test]`. Run `terragrunt run-all plan -destroy` to see what will be destroyed.
1. If there were no errors, run `terragrunt run-all destroy` to destroy the Concourse deployment in the current region.

## Recreate the Concourse Deployment
1. In the `config.yaml`, change the project's region and zones. Example for `us-east1`:
   ```yaml
   region: us-east1
   zone: us-east1-b
   secondary_zone: us-east1-c
   ```
1. Check the Postgres version in the [Concourse Helm chart](https://github.com/concourse/concourse-chart/blob/master/Chart.yaml). If the database version must be updated, change the `database_version` value:
   ```yaml
   database_version: "POSTGRES_16"
   ```
1. Check the [GKE release notes](https://cloud.google.com/kubernetes-engine/docs/release-notes) for the latest supported version. If the GKE version must be updated, change the `gke_version` value:
   ```yaml
   gke_controlplane_version: "1.31"
   ```
1. Revert the changes in the Terraform files:
   - In `terraform-modules/concourse/dr_create/credhub_encryption_key.tf`, uncomment the "lifecycle" block.
   - Uncomment module "assertion_encryption_key_identical" (if you commented it before).
   - In `terraform-modules/concourse/infra/database.tf`, set `deletion_protection` and `deletion_protection_enabled` to `true`.
   - In `terraform-modules/concourse/infra/gke_cluster.tf`, remove `deletion_protection = false`.
1. Now you can check the Terraform plan:
   ```bash
   terragrunt run-all plan
   ```
1. If you see `Error: Unsupported OpenTofu Core version`, comment module "assertion_encryption_key_identical".
1. If there are no errors, apply the changes:
   ```bash
   terragrunt run-all apply
   ```
1. Only for wg-ci-test: To make the "e2e_test" pass, you must log on with the fly CLI and run the "apply" step again:
   ```bash
   fly -t wg-ci-test login -c https://concourse-test.app-runtime-interfaces.ci.cloudfoundry.org
   ```
1. Refresh your `kubectl` context to the new region:
   ```bash
   gcloud container clusters get-credentials wg-ci[-test] --region us-east1-b
   ```
1. Log on to CredHub with the [start-credhub-cli.sh](../../terragrunt/scripts/concourse/start-credhub-cli.sh) script. Copy the credential backup file from to the pod:
   ```bash
   kubectl -n default cp credhub_backup.json credhub-cli-<id>:/go/credhub_backup.json
   ```
   Then import all data:
   ```bash
   credhub import -j -f credhub_backup.json
   ```
1. Restart the Cloud SQL Auth Proxy with the new "Connection name".
1. Stop the "web" pod:
   ```bash
   kubectl -n concourse scale deployment concourse-web --replicas=0
   ```
1. Retrieve the new database password:
   ```bash
   kubectl -n concourse get secret concourse-postgresql-password -o yaml | yq -r .data.password | base64 -d
   ```
1. Drop the existing "concourse" database:
   ```bash
   psql -h 127.0.0.1 -p 5432 -U concourse -d postgres
   DROP DATABASE concourse;
   CREATE DATABASE concourse;
   ```
1. Restore the Concourse database from the backup:
   ```bash
   psql -h 127.0.0.1 -p 5432 -U concourse -d concourse -f concourse_backup.sql
   ```
   There should be no errors like "relation already exists" or constraint violations.
1. Restart the "web" pod:
   ```bash
   kubectl -n concourse scale deployment concourse-web --replicas=1
   ```
