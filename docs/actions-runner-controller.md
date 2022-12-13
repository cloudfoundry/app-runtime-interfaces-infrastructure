# Actions Runner Controller

Deployment for ARC controller operates self-hosted runners for GitHub Actions on a Kubernetes cluster. Terraform modules consist of two parts to be deployed on the [infrastructure](../terraform-modules/actions_runner_controller/infra/) and to be consumed by [the team](../terraform-modules/actions_runner_controller/team/).


ARC on [Github](https://github.com/actions-runner-controller/actions-runner-controller)

Detailed [documentation](https://github.com/actions-runner-controller/actions-runner-controller/blob/master/docs/detailed-docs.md)

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


## Team

This terraform module is intended to be consumed by the team and runs in `<team-name>-actions-runners`:
* GKE node pool for the team
* Horizontal Pod Autoscaling with Stateful Set for arc runners pods
* Dedicated GKE Storage Class for PVs consumed by pods used for docker image caching
* Provisioning of required webhook server in your GitHub repository

*Note* - Secret required in GCP Secret Manager:
* webhook server token used at webhook server side and GitHub webhook side