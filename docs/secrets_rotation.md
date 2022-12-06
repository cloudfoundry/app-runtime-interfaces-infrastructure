# Secrets Rotation (CloudSQL)

Automated secrets rotation for sql users is available with provided bash script.

## Prerequistes
Folder for terragrunt with corresponding .hcl file (or alternative invocation via your terraform method)

Required specification for module source in `config.yaml` and `.hcl` file

See example in ...

## To invoke secrets rotation

1. Follow instructions for [asdf install](../README.md#required-tools) and [logon to GCP account](../README.md#2-logon-to-your-gcp-account)

2. `cd` to folder with your concourse cluster. ie:
    ```
    cd terragrunt/concourse-wg-ci-test
    ```

3. Execute rotation script
    ```
    ../scritps/secret_rotation_postgresql.sh
    ```

## Procedure

The script will read configuration from `config.yaml` and create required configuration for `kubectl`.

If the script will find your cluster name doesn't contain keyword `test` you will be required to additionally confirm the action.

Following, the script will show you the age of secrets and present with information on acctions to apply:
* deletion of current secrets
* bouncing secretgen controller pod to generate new passwords
* bouncing application stack pods with terraform to consume new secrets:
  * concourse-web
  * concourse-worker
  * credhub
  * uaa
* a check awaiting application deployments to become available

## Completion time
Estimated completion time should be not longer than 200 seconds. The longest awaiting time is for UAA to populate java trustore with CA certificates.