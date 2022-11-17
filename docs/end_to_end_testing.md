# End to end (e2e) testing

Additional module in terraform-modules for e2e testing

Use cases:
* continuous integration
* new features
* disaster recovery testing

## How to use:
setup and logon with gcloud auth
```
gcloud auth login && gcloud auth application-default login
```
## Setup fly
```
`fly login -t <gke_name> -c https://<your concourse url> -n <your team default:main>`
```

## Execute
Use terraform or see example terragrunt code in [terragrunt/concourse-wg-ci-test](../terragrunt/concourse-wg-ci-test/e2e-test/)