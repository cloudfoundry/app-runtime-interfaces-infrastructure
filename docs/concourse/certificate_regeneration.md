# Automated certificate regeneration

You can deploy a K8s CronJob to automatically regenerate certificates which are stored in CredHub. A typical example are load balancer certificates used in a bosh-bootloader environment. The CronJob calls `credhub regenerate <certificate name>`. This will extend the certificate's validity while all other properties remain unchanged.

The automated regeneration is provided as separate Terragrunt module which must be deployed separately to enable the feature.

## Prerequisites

The certificate's CA must be stored in CredHub, and the certificate must be correctly linked to the CA.

## Configuration and deployment

First, configure the list of certificates in your local `config.yaml`. Define one string with comma-separated certificate names, e.g.:
```
certificates_to_regenerate: "/concourse/main/cert_1,/concourse/main/cert_2"
```

Next, change to the directory `terragrunt/<concourse-instance>/automatic_certificate_regeneration` and call
```
terragrunt apply --config=cert_regen.hcl
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
Afterward, you should delete the job with:
```
kubectl -n concourse delete job cert-regen-job
```

## Limitations

It's possible to renew CAs with the CronJob. Note however that this would be a one-step renewal process which can result in downtimes. The full 4-step CA renewal process as described on https://github.com/pivotal/credhub-release/blob/main/docs/ca-rotation.md is not implemented.

If you want to include the CA in the regeneration process, you can add it at the beginning of the list:
```
certificates_to_regenerate: "/concourse/main/my_CA,/concourse/main/cert_1,/concourse/main/cert_2"
```
The (self-signed) CA would be regenerated first and then the two certificates would be re-signed with the new CA and the validity would be extended.

## Deletion

To delete the CronJob, change to the directory `terragrunt/<concourse-instance>/automatic_certificate_regeneration` and call
```
terragrunt destroy --config=cert_regen.hcl
```