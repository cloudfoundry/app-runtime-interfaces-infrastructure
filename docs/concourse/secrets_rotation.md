# Secrets Rotation (CloudSQL)

Automated secrets rotation for sql users is available with provided bash script.

## Prerequistes
Folder for terragrunt with corresponding .hcl file (or alternative invocation via your terraform method)

Required specification for module source in `config.yaml` and `.hcl` file

See [example.](../terragrunt/concourse-wg-ci/secret_rotation_postgresql/)

## To invoke secrets rotation

1. Follow instructions for [asdf install](../README.md#required-tools) and [logon to GCP account](../README.md#2-logon-to-your-gcp-account)

2. `cd` to the folder with your concourse cluster. ie:
    ```
    cd terragrunt/concourse-wg-ci-test
    ```

3. Execute rotation script
    ```
    ../scritps/concourse/secret_rotation_postgresql.sh
    ```

## Procedure

The script will read configuration from `config.yaml` and create required configuration for `kubectl`.

If the script will find your cluster name doesn't contain keyword `test` you will be required to additionally confirm the action.

Following, the script will show you the age of secrets and present with information on actions to apply:
* deletion of current concourse postgresql secrets
* bouncing secretgen controller pod to generate new passwords
* bouncing application stack pods with terraform to consume new secrets:
  * concourse-web
  * concourse-worker
  * credhub
  * uaa
* a check awaiting application deployments to become available

## Completion time
Estimated completion time should be not longer than 200 seconds. The longest awaiting time is for UAA to populate java trustore with CA certificates.

## Transcript of expected execution
```
../scritps/concourse/secret_rotation_postgresql.sh   
>> Fetching kubectl config for cluster: wg-ci-test | project: app-runtime-interfaces-wg | zone: europe-west3-a
Fetching cluster endpoint and auth data.
kubeconfig entry generated for wg-ci-test.

Invoking secrets rotation. The following actions will be applied:

  - postgresql k8s secrets: delete (in concourse namespace)
  - secretgen controller: pod restart to refresh new sql passwords in k8s secrets
  - cloud sql users: passwords sync from k8s secrets for respective sql users
  - application pods restart to refresh new config:
    - concourse-web
    - concourse-worker (k8s nodepool autoscaling will be triggered)
    - credhub
    - uaa

>> Show existing secrets and their age
concourse-postgresql-password          kubernetes.io/basic-auth              1      17h
credhub-postgresql-password            kubernetes.io/basic-auth              1      17h
uaa-postgresql-password                kubernetes.io/basic-auth              1      17h

Please confirm with 'yes' to continue: yes

>> Deleting existing postgresql secrets
secret "concourse-postgresql-password" deleted
secret "credhub-postgresql-password" deleted
secret "uaa-postgresql-password" deleted

>> Restarting secretgen controller pod [1/2]: scale down to 0 replicas
deployment.apps/secretgen-controller scaled

>> Restarting secretgen controller pod [1/2]: scale back up to 1 replicas
deployment.apps/secretgen-controller scaled

>> Wating to confirm secretgen controllers replicas=1
deployment.apps/secretgen-controller condition met

>> Waiting for secrets
Error from server (NotFound): secrets "concourse-postgresql-password" not found
Waiting for secret: concourse-postgresql-password
NAME                            TYPE                       DATA   AGE
concourse-postgresql-password   kubernetes.io/basic-auth   1      0s
NAME                          TYPE                       DATA   AGE
credhub-postgresql-password   kubernetes.io/basic-auth   1      1s
NAME                      TYPE                       DATA   AGE
uaa-postgresql-password   kubernetes.io/basic-auth   1      1s

>> Wait for secrets update from secretgen controller
secret/concourse-postgresql-password condition met
secret/credhub-postgresql-password condition met
secret/uaa-postgresql-password condition met

>> Show new postgresql secrets and their age
concourse-postgresql-password          kubernetes.io/basic-auth              1      3s
credhub-postgresql-password            kubernetes.io/basic-auth              1      3s
uaa-postgresql-password                kubernetes.io/basic-auth              1      3s

>> Apply terragrunt (with resource show) to synchronise kubernetes secrets with CloudSQL Users

Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of hashicorp/google from the dependency lock file
- Reusing previous version of hashicorp/kubernetes from the dependency lock file
- Installing hashicorp/google v4.45.0...
- Installed hashicorp/google v4.45.0 (signed by HashiCorp)
- Installing hashicorp/kubernetes v2.16.1...
- Installed hashicorp/kubernetes v2.16.1 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
data.google_client_config.provider: Reading...
data.google_container_cluster.wg_ci: Reading...
data.google_client_config.provider: Read complete after 0s [id=projects//regions//zones/]
data.google_container_cluster.wg_ci: Read complete after 1s [id=projects/app-runtime-interfaces-wg/locations/europe-west3-a/clusters/wg-ci-test]
data.kubernetes_secret_v1.sql_user_password["credhub"]: Reading...
data.kubernetes_secret_v1.sql_user_password["uaa"]: Reading...
data.kubernetes_secret_v1.sql_user_password["concourse"]: Reading...
data.kubernetes_secret_v1.sql_user_password["credhub"]: Read complete after 0s [id=concourse/credhub-postgresql-password]
data.kubernetes_secret_v1.sql_user_password["concourse"]: Read complete after 0s [id=concourse/concourse-postgresql-password]
data.kubernetes_secret_v1.sql_user_password["uaa"]: Read complete after 0s [id=concourse/uaa-postgresql-password]
google_sql_user.sql_user_pass_restored["uaa"]: Refreshing state... [id=uaa//wg-ci-test-concourse]
google_sql_user.sql_user_pass_restored["credhub"]: Refreshing state... [id=credhub//wg-ci-test-concourse]
google_sql_user.sql_user_pass_restored["concourse"]: Refreshing state... [id=concourse//wg-ci-test-concourse]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # google_sql_user.sql_user_pass_restored["concourse"] will be updated in-place
  ~ resource "google_sql_user" "sql_user_pass_restored" {
        id                      = "concourse//wg-ci-test-concourse"
        name                    = "concourse"
      ~ password                = (sensitive value)
        # (5 unchanged attributes hidden)
    }

  # google_sql_user.sql_user_pass_restored["credhub"] will be updated in-place
  ~ resource "google_sql_user" "sql_user_pass_restored" {
        id                      = "credhub//wg-ci-test-concourse"
        name                    = "credhub"
      ~ password                = (sensitive value)
        # (5 unchanged attributes hidden)
    }

  # google_sql_user.sql_user_pass_restored["uaa"] will be updated in-place
  ~ resource "google_sql_user" "sql_user_pass_restored" {
        id                      = "uaa//wg-ci-test-concourse"
        name                    = "uaa"
      ~ password                = (sensitive value)
        # (5 unchanged attributes hidden)
    }

Plan: 0 to add, 3 to change, 0 to destroy.
google_sql_user.sql_user_pass_restored["credhub"]: Modifying... [id=credhub//wg-ci-test-concourse]
google_sql_user.sql_user_pass_restored["uaa"]: Modifying... [id=uaa//wg-ci-test-concourse]
google_sql_user.sql_user_pass_restored["concourse"]: Modifying... [id=concourse//wg-ci-test-concourse]
google_sql_user.sql_user_pass_restored["uaa"]: Modifications complete after 1s [id=uaa//wg-ci-test-concourse]
google_sql_user.sql_user_pass_restored["concourse"]: Modifications complete after 2s [id=concourse//wg-ci-test-concourse]
google_sql_user.sql_user_pass_restored["credhub"]: Modifications complete after 3s [id=credhub//wg-ci-test-concourse]

Apply complete! Resources: 0 added, 3 changed, 0 destroyed.

Scaling down deployments: concourse-web concourse-worker credhub uaa
deployment.apps/concourse-web scaled
deployment.apps/concourse-worker scaled
deployment.apps/credhub scaled
deployment.apps/uaa scaled

Scaling up deployments: concourse-web concourse-worker credhub uaa
deployment.apps/concourse-web scaled
deployment.apps/concourse-worker scaled
deployment.apps/credhub scaled
deployment.apps/uaa scaled

>> Wait for deployments available
deployment.apps/concourse-web condition met
deployment.apps/concourse-worker condition met
deployment.apps/credhub condition met
deployment.apps/uaa condition met

Completed
```