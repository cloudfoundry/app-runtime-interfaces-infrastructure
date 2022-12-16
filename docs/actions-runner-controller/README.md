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
    * `tf_modules.github_arc` to point to a remote terraform-modules or local disk path

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

This part lives independently of the infra part and can be consumed by multiple teams providing mentioned GitHub account configured in arc controller can access various teams' repositories.

1. Copy [an example terragrunt template](./terragrunt-team-example/) to your repository

2. Adjust `config.yaml`. You should at least look at the following"
    * `project / region / zone`
    * `gcs_bucket`
    * `team_name` (note service account name length limit made of *gke_name+team_name-pool* is 28 chars)
    * `gke_name`
    * `arc_webhook_server_domain`
    *  adjust _repository name/owner_, _node pool machine type_ and _resources requests/limits_ to fit your expected scaling demands in
        * `gke_arc_node_pool_machine_type`
        * `github_repos`
        * when running multiple repositories additionally adjust amount of `gke_arc_node_pool_autoscaling_max` to satisfy k8s scaling demands
    * `tf_modules.github_arc` to point to a remote terraform-modules or local disk path
    * `var_lib_docker_size` sets the PersistentVolume for docker used for docker images caching

3. Set the environment variable `GITHUB_TOKEN` in your terminal
Missing this part will result in errors when creating webhook in your repositories
    ```
    export GITHUB_TOKEN="ghp..."
    ```

4. Run terragrunt
    ```
    # cd to folder with config.yaml

    terragrunt apply
    ```
Estimated completion time for infrastructure:
* terragrunt: 3 minutes


## Workarounds applied

### Terraform github_repository_webhook

The way [github_repository_webhook](https://registry.terraform.io/providers/integrations/github/latest/docs#owner) provider has been made would prevent scaling creation of webhooks for multiple repositories per team via single terraform team module. Each team would need to configure multiple providers with hardcoder owner set per repository.

The workaround here is achieved with a bypass in the provider setting with a "weird" owner name in [providers.tf block](../../terraform-modules/actions_runner_controller/team/providers.tf)

```
provider "github" {
  owner = "./"
}

```

Following similar bypass is used in [arc_webhook_github.tf](../../terraform-modules/actions_runner_controller/team/arc_webhook_github.tf) file

```
resource "github_repository_webhook" "github_webhook" {
    for_each = { for repo in var.github_repos: repo.name => repo }

    repository = "../${each.value.owner}/${each.value.name}"
    configuration {
      ...
    }
    ...
```

This allows to override provider config and builds API call to github in a scalable way.

Corresponding [feature request](https://github.com/integrations/terraform-provider-github/issues/1436) has been created on GitHub

## Limitations

### No control over deletion of Persistent Volumes (/var/lib/docker)

At the time of writing this document [a github feature request](https://github.com/actions/actions-runner-controller/issues/2092) was created in the Actions Runner Controller repository with regards to the inability to delete PVs for runner pods.

PVs do persist across runner pods creation/deletion however without external job to remove them, they will consume resources when they might not be needed (ie. overnight or over the weekends)

To ease potential short-term solution with a Kubernetes Job PV removal task APVs with state Available can be removed with cron task filtering for PVS using team-named Storage Classes

### ARC controller can use only a single github repository access OAuth token

With a use case of multiple teams consuming against the same GKE github account need to have admin permissions across the repositories to register github runners.
