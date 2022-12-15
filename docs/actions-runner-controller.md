# Actions Runner Controller

Deployment for ARC controller operates self-hosted runners for GitHub Actions on a Kubernetes cluster. Terraform modules consist of two parts to be deployed on the [infrastructure](../terraform-modules/actions_runner_controller/infra/) and to be consumed by [the team](../terraform-modules/actions_runner_controller/team/).


ARC on [Github](https://github.com/actions-runner-controller/actions-runner-controller)

Detailed ARC [documentation](https://github.com/actions-runner-controller/actions-runner-controller/blob/master/docs/detailed-docs.md)

## Infrastructure

This terraform module will deploy the following components in `actions-runner-system` namespace:
* ARC controller with Webhook Server based autoscaling facility
* [cert-manager](https://cert-manager.io/)
  * used for ARC webhook and LetsEncrypt certificate for Webhook Server
* DNS to provision and manage webhook server IP and address
* ARC Webhook Server loadbalancer with LetsEncrypt TLS facility
  * LetsEncrypt is supported with production and staging type of certificates.
* GKE firewall rule for ARC internal webhook

*Note* - Secrets required in GCP Secret Manager:
* GitHub repository token with admin access for registering self-hosted runners
  * Provided with a corresponding [script](../terragrunt/scritps/actions-controller/create-github-access-token-gcp.sh)
  * GithubAccess token is required to have access to all repositories used by teams within the working group


## Team

This terraform module is intended to be consumed by the team and runs in `<team-name>-actions-runners`:
* GKE node pool for the team
* Horizontal Pod Autoscaling with Stateful Set for arc runners pods
* Dedicated GKE Storage Class for PVs consumed by pods used for docker image caching
* Provisioning of required webhook server in your GitHub repository

*Note* - Secret required in GCP Secret Manager:
* ARC Webhook Server token used at webhook server side and GitHub webhook side
  * Provided with a corresponding [script](../terragrunt/scritps/actions-controller/create-arc-webhook-server-token-gcp.sh)


## The infrastructure part - new installation
Since actions-runner-controller-proxy uses a ClusterRole this controller can be installed only once across the cluster.

The project assumes a GKE cluster is available.

1. Copy the example code to your repository
   * `terragrunt/github-arc-infra-wg-ci-test`
   * `terragrunt/scripts/actions-controller` folder

2. Amend `config.yaml` to your needs. You should at least look at:
    * `project / region / zone`
    * `gcs_bucket / gcs_prefix`
    * `gke_name`
    * `arc_github_access_token_name`
    * `arc_letsencrypt_notifications_email`
    * `dns_zone / dns_domain`

1. Generate GCP secret with github access token key.
    ```
    # Generate oauth token for your github account.

    # Provide the token in `token=` variable in the script

    # cd to folder with config.yaml ie `github-arc-infra-wg-ci-test`

    ../scritps/actions-controller/create-github-access-token-gcp.sh
    ```

2. Generate token for ARC Webhook Server
    ```
    # cd to folder with config.yaml ie `github-arc-infra-wg-ci-test`

    ../scritps/actions-controller/create-arc-webhook-server-token-gcp.sh
    ```

    The script will generate a random hex token and store it in GCP Secrets Manager. The same token will be used to create a webhook in your github repositories.

Estimated completion time for infrastructure:
* terragrunt: 3 minutes
* load balancer: additional 12 minutes
## The team part
