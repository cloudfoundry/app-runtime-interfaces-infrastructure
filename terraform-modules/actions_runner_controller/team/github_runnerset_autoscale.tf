resource "kubernetes_namespace" "github_actions_runners" {
    metadata {
    name = "${var.team_name}-actions-runners"
  }
}


# resource "kubectl_manifest" "github_repo_runners_autoscaler" {
#   yaml_body = <<EOT
# apiVersion: actions.summerwind.dev/v1alpha1
# kind: HorizontalRunnerAutoscaler
# metadata:
#   name: "${var.github_repo_name}-hpa"
#   namespace: "${kubernetes_namespace.github_actions_runners.metadata[0].name}"
# spec:
#   minReplicas: 0
#   maxReplicas: 16
#   scaleTargetRef:
#     kind: RunnerSet
#     name: "${var.github_repo_name}-runnerset"
#   scaleUpTriggers:
#     - githubEvent:
#         workflowJob: {}
#         duration: "${var.hpa_scaleup_trigger_duration}"
#   scaleDownDelaySecondsAfterScaleOut: ${var.hpa_scaledown_delay_seconds}
# EOT
# }

# resource "kubectl_manifest" "github_repo_runnerset" {
#   yaml_body = <<EOT
# apiVersion: actions.summerwind.dev/v1alpha1
# kind: RunnerSet
# metadata:
#   name: "${var.github_repo_name}-runnerset"
#   namespace: "${kubernetes_namespace.github_actions_runners.metadata[0].name}"
# spec:
#   repository: "${var.github_repo_owner}/${var.github_repo_name}"
#   selector:
#    matchLabels:
#      app: "${var.team_name}-arc-workers"
#   serviceName: "${var.team_name}-service"

#   template:
#     metadata:
#       labels:
#         app: "${var.team_name}-arc-workers"
#     spec:
#       affinity:
#         nodeAffinity:
#           requiredDuringSchedulingIgnoredDuringExecution:
#             nodeSelectorTerms:
#             - matchExpressions:
#               - key: cloud.google.com/gke-nodepool
#                 operator: In
#                 values:
#                 - "${var.team_name}-arc-workers"
#       tolerations:
#       - effect: NoSchedule
#         key: "${var.team_name}-arc-workers"
#         operator: Equal
#         value: "true"
#       containers:
#       - name: docker
#         volumeMounts:
#         - name: var-lib-docker
#           mountPath: /var/lib/docker
#       - name: runner
#         resources:
#           requests:
#             cpu: "${var.runnerset_resource_request_cpu}"
#             memory: "${var.runnerset_resource_request_mem}"

#   volumeClaimTemplates:
#   - metadata:
#       name: var-lib-docker
#     spec:
#       accessModes:
#       - ReadWriteOnce
#       resources:
#         requests:
#           storage: 20Gi
#       storageClassName: "${var.team_name}-arc-regional"

# EOT

# depends_on = [ google_container_node_pool.team_github_arc, kubernetes_storage_class_v1.arc_regional ]

# }