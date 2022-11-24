resource "kubernetes_namespace" "github_actions_runners" {
  metadata {
    name = "actions-runner-workers"
  }
}

resource "kubectl_manifest" "runner_deployment" {
  yaml_body = <<EOT
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: autoscaler-arc-worker
  namespace: actions-runner-workers
spec:
  replicas: 4
  template:
    metadata:
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
    spec:
      tolerations:
      - effect: NoSchedule
        key: github-arc-workers
        operator: Equal
        value: "true"
      repository: cloudfoundry/app-autoscaler-release
EOT
}