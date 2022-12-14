# Concourse Minor Version Upgrade

Following is a tested upgrade path for a minor version upgrade of Concourse (partially manual).

The process assumes the usage of terragrunt Concourse stack.

Please note the process should be also useful for upgrading major versions.

## Roll-in procedure

1. Connect to your GCP account
   ```
   gcloud auth login && gcloud auth application-default login
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
    ../scripts/create-sql-backup.sh
    ```

6. Apply roll-out for new Concourse version
   ```
   terragrunt run-all plan --terragrunt-source-update
   ```

At this point depending on your use case:

1. Update `fly` to new minor version ie. change version in `.tool-versions` and run `asdf install`

2. Login to the new Concourse
   ```
   fly login -t <target name>

3. For `wg-ci-test` cluster: execute end-to-end test
   ```
   cd e2e_test
   terragrunt apply --terragrunt-source-update
   cd ..
   ```

## Roll-back procedure

To guarantee SQL databases consistency delete Concourse deployment and restore SQL instance

1. Obtain credentials for kubectl to kubernetes and delete Concourse deployments
   ```
   kubectl -n concourse delete deployment concourse-worker
   kubectl -n concourse delete deployment concourse-web
   ```

2. Restore on-demand sql instance backup - use Web UI or gcloud command

3. Run concourse stack deployment
   ```
   terragrunt run-all plan
   terragrunt run-all apply
   ```

4. Set back to previous version of `fly` binary
