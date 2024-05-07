# Automated certificate regeneration

You can deploy a K8s CronJob to automatically regenerate certificates which are stored in CredHub. A typical example are load balancer certificates used in a bosh-bootloader environment. The CronJob calls `credhub regenerate <certificate name>`. This will extend the certificate's validity while all other properties remain unchanged.

The automated regeneration is provided as separate Terragrunt module which must be deployed separately to enable the feature.

## Prerequisites

The certificate's CA must be stored in CredHub, and they must be correctly linked.

## Configuration and deployment

First, configure the list of certificates in your local `config.yaml`. Define one string with comma-separated certificate names, e.g.:
```
certificates_to_regenerate: "/concourse/main/cert_1,/concourse/main/cert_2"
```

Next, change to the directory `terragrunt/<concourse-instance>/automatic_certificate_regeneration` and call
```
terragrunt apply --terragrunt-config cert_regen.hcl
```
You should see that Terraform creates a new resource:
```
resource "kubernetes_cron_job_v1" "automatic_certificate_regeneration"
(...)
```
Confirm with `yes`. Afterward, you can see a new CronJob in your K8s deployment:
```
$ kubectl -n concourse get cronjobs
NAME                       SCHEDULE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
certificate-regeneration   @monthly   False     0        <none>          50m
```
To test the CronJob, you can invoke it explicitly and check the logs:
```
kubectl -n concourse create job --from=cronjob/certificate-regeneration cert-regen-job
# wait a few seconds
kubectl -n concourse get pods # search pod "cert-regen-job-<xyz>"
kubectl -n concourse logs cert-regen-job-<xyz>
```
You should see the output from CredHub:
```
id: 68875a90-c1b7-4391-a2af-bd3a8f33ce47
name: /concourse/main/cert_1
type: certificate
value: <redacted>
version_created_at: "2024-05-07T12:23:43Z"
(...)
```

## Deletion

To delete the CronJob, change to the directory `terragrunt/<concourse-instance>/automatic_certificate_regeneration` and call
```
terragrunt destroy --terragrunt-config cert_regen.hcl
```