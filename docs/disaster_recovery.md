# Disaster Recovery
## Prerequisites

1. The backup of credhub encryption key has been stored in GCP Secret Manager - this part is handled automatically with `dr_creste` terragrunt part of the stack
2. The secret in GCP was not deleted/altered manually.
3. Credhub database exists or is available or recovered from a backup.


## DR scenario tested
deleted the entire deployment including 'concourse' namespace
* deleted all databases and database users with db recovered from backup
* GKE cluster destroyed



## Steps
Fully automated restore with:
```
cd <folder witg config.yaml>
../scripts/dr-restore.sh
```

## Troubleshooting

### DR credhub encryption check

The dr_create module will check for the existence and integrity of the Credhub encryption key. Following errors may appear if the user does not execute dr-create
1. Crehub encryption key does not exist in google secret manager or has no version
   ```
   │ Error: Error retrieving available secret manager secret versions: googleapi: Error 404: Secret [projects/899763165748/secrets/wg-ci-test-credhub-encryption-key] not found or has no versions.
   │
   │   with data.google_secret_manager_secret_version.credhub_encryption_key,
   │   on credhub_dr_check.tf line 2, in data "google_secret_manager_secret_version" "credhub_encryption_key":
   │    2: data "google_secret_manager_secret_version" "credhub_encryption_key" {
   │
   ```
2. Credhub encryption keys stored in google secrets manager is different to the one stored in kubernetes secret 
    ```
    │ Error: Call to unknown function
    │ 
    │   on .terraform/modules/assertion_encryption_key_identical/.tf line 6, in locals:
    │    6:   content = var.condition ? "" : SEE_ABOVE_ERROR_MESSAGE(true ? null : "ERROR: ${var.error_message}")
    │     ├────────────────
    │     │ var.error_message is "*** Encryption keys in GCP Secret Manager and kubernetes secrets do not match ***"
    │ 
    │ There is no function named "SEE_ABOVE_ERROR_MESSAGE".
    ```

### Unexpected credhub encryption-key-in k8s secrets
Providing GKE cluster or application was removed recovery is not expecting credhub-encryption-key stored in kubernetes secrets. Please remove it from k8s since it will be restored from GCP Secret Manager.

```
╷
│ Error: secrets "credhub-encryption-key" already exists
│
│   with kubernetes_secret_v1.credhub_encryption_key,
│   on credhub_restore.tf line 6, in resource "kubernetes_secret_v1" "credhub_encryption_key":
│    6: resource "kubernetes_secret_v1" "credhub_encryption_key" {
│
╵
```

###  Carvel kapp is unwilling to apply backend changes

   In case carvel kapp is unwilling to apply backend changes you can taint it and re-provision.
  _WARNING_ proceed with caution if you use the backend in other projects on the cluster (ie. carvel secret gen). Shall this be a case secretgen should not be a part of managed concourse deployment anymore.

```
cd ./backend
terragrunt taint carvel_kapp.concourse_backend
terragrunt plan
terragrunt apply
```
Re-run dr restore
```
cd ..
../scripts/dr_restore.sh
```