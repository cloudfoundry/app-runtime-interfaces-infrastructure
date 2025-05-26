# Concourse Minor Version Upgrade

Following is a tested upgrade path for a minor version upgrade of Concourse (partially manual).

The process assumes the usage of the Terragrunt Concourse stack.

Please note the process should be also useful for upgrading major versions.

## Roll-in Procedure

1. Connect to your GCP account
   ```
   gcloud auth login && gcloud auth application-default login
   gcloud config set project <your project name>
   ```

2. `cd` to a folder with concourse folder with `config.yaml` file

3. Confirm there are no pending changes for the Concourse stack
   ```
   terragrunt run-all plan --terragrunt-source-update
   ```

4. Switch to `renovate's` pull request having bumped Concourse helm chart version
   ```
   git pull
   git checkout renovate/concourse-17.x
   ```

5. Create on-demand SQL instance backup
   ```
   ../terragrunt/scripts/concourse/create-sql-backup.sh
   ```

6. Check Cloud SQL "Data Protection" settings

In the GCP console, navigate to:
https://console.cloud.google.com/sql/instances/ -> select instance name -> edit -> Data Protection

Make sure the following flags are enabled:
* "Prevent instance deletion"
* "Retain backups after instance deletion"

7. Apply roll-out for new Concourse version
   ```
   terragrunt run-all apply --terragrunt-source-update
   ```

At this point depending on your use case:

1. Update `fly` to new minor version i.e. change the version in `.tool-versions` and run `asdf install`

2. Login to the new Concourse
   ```
   fly login -t <target name>
   ```

3. For `wg-ci-test` cluster: execute end-to-end test
   ```
   cd e2e_test
   terragrunt apply --terragrunt-source-update
   cd ..
   ```

## Roll-back Procedure

To guarantee SQL databases consistency delete Concourse deployment and restore SQL instance

1. Obtain credentials for kubectl to Kubernetes and delete Concourse deployments
   ```
   kubectl -n concourse delete deployment concourse-worker
   kubectl -n concourse delete deployment concourse-web
   ```

2. Restore on-demand SQL instance backup - use Web UI or gcloud command

3. Run Concourse stack deployment
   ```
   terragrunt run-all plan
   terragrunt run-all apply
   ```

4. Set back to the previous version of the `fly` binary
