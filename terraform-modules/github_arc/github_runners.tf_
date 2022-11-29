resource "kubernetes_namespace" "github_actions_runners" {
  metadata {
    name = "actions-runner-workers"
  }
}

# resource "kubectl_manifest" "runner_autoscaler" {
#   yaml_body = <<EOT
# apiVersion: actions.summerwind.dev/v1alpha1
# kind: HorizontalRunnerAutoscaler
# metadata:
#   name: autoscaler-arc-autoscaler
#   namespace: actions-runner-system
# spec:
#   minReplicas: 2
#   maxReplicas: 10
#   scaleTargetRef:
#     kind: RunnerDeployment
#     name: autoscaler-arc-workers
#   scaleUpTriggers:
#     - githubEvent:
#         workflowJob: {}
#       duration: "30m"
# }
resource "kubectl_manifest" "runner_deployment" {
  yaml_body = <<EOT
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: autoscaler-arc-workers
  namespace: actions-runner-workers
spec:
  replicas: 4
  template:
    spec:
      tolerations:
      - effect: NoSchedule
        key: github-arc-workers
        operator: Equal
        value: "true"
      repository: cloudfoundry/app-autoscaler-release
EOT

depends_on = [google_container_node_pool.github_arc ]

}