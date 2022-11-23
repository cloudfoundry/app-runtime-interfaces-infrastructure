# Developer notes

# Plan/apply terragrunt for changes to modules
Update your terragrunt cache folders when terraform source modules code would change
```sh
terragrunt run-all plan --terragrunt-source-update
```

## Upgrade components managed by kapp and vendir (when needed)
Required actions:
* changing charts versions
* `vendir sync`

## Versioning with vendir
```
cd ./files
```
Update `vendir.yml`
```
vendir sync
```
Commit changes to the git repo.

## Warining on UAA deployment
File [app/files/config/uaa/_ytt_lib/uaa/k8s/templates/deployment.star](../terraform-modules/concourse/app/files/config/uaa/_ytt_lib/uaa/k8s/templates/deployment.star) has been altered manually and removes `"-DSECRETS_DIR={}".format(secrets_dir),` line from the original template.


When present, this parameter will prevent uaa pod to populate `UAA_POSTGRES_HOST` env variable

**When running `vendor sync` for new version the parameter will need to be removed again**

## Drawio editable svg diagram

We use png format to keep white background.

## Terraform modules versioning
Please follow [semantic versioning](https://semver.org/).

At present tagging is done manually.
