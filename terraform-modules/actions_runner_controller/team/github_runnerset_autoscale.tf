resource "kubernetes_namespace" "github_actions_runners" {
    metadata {
    name = "${var.team_name}-actions-runners"
  }
}


resource "kubectl_manifest" "github_repo_runners_hpa" {
  for_each = { for repo in var.github_repos: repo.name => repo }

  yaml_body = <<EOT
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: "${each.value.owner}--${each.value.name}"
  namespace: "${kubernetes_namespace.github_actions_runners.metadata[0].name}"
spec:
  minReplicas: 0
  maxReplicas: 16
  scaleTargetRef:
    kind: RunnerSet
    name: "${each.value.owner}--${each.value.name}"
  scaleUpTriggers:
    - githubEvent:
        workflowJob: {}
        duration: "${each.value.hpa_scaleup_trigger_duration}"
  scaleDownDelaySecondsAfterScaleOut: ${each.value.hpa_scaledown_delay_seconds}
EOT

depends_on = [ google_container_node_pool.team_github_arc ]
}

resource "kubectl_manifest" "github_repo_runnerset" {
  for_each = { for repo in var.github_repos: repo.name => repo }

  yaml_body = <<EOT
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerSet
metadata:
  name: "${each.value.owner}--${each.value.name}"
  namespace: "${kubernetes_namespace.github_actions_runners.metadata[0].name}"
spec:
  repository: "${each.value.owner}/${each.value.name}"
  selector:
   matchLabels:
     app: "${var.team_name}-arc-workers"
  serviceName: "${var.team_name}-service"

  template:
    metadata:
      labels:
        app: "${var.team_name}-arc-workers"
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: cloud.google.com/gke-nodepool
                operator: In
                values:
                - "${var.team_name}-arc-workers"
      tolerations:
      - effect: NoSchedule
        key: "${var.team_name}-arc-workers"
        operator: Equal
        value: "true"
      containers:
      - name: docker
        volumeMounts:
        - name: var-lib-docker
          mountPath: /var/lib/docker
      - name: runner
        resources:
          requests:
            cpu: ${each.value.runnerset_resource_request_cpu}
            memory: ${each.value.runnerset_resource_request_mem}
          limits:
            cpu: ${each.value.runnerset_resource_limits_cpu}
            memory: ${each.value.runnerset_resource_limits_mem}
  volumeClaimTemplates:
  - metadata:
      name: var-lib-docker
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: ${each.value.var_lib_docker_size}
      storageClassName: "${var.team_name}-arc-regional"

EOT

depends_on = [ google_container_node_pool.team_github_arc, kubernetes_storage_class_v1.arc_regional ]

}