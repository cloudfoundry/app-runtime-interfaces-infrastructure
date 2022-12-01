resource "kubernetes_namespace" "github_actions_runners" {
  metadata {
    name = "actions-runner-workers"
  }
}


resource "kubectl_manifest" "app_autoscaler_release_runners_autoscaler" {
  yaml_body = <<EOT
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: autoscaler-arc-autoscaler
  namespace: actions-runner-system
spec:
  minReplicas: 2
  maxReplicas: 10
  scaleTargetRef:
    kind: RunnerSet
    name: autoscaler-arc-runnerset
    #repository: cloudfoundry/app-autoscaler-release
  scaleUpTriggers:
    - githubEvent:
        workflowJob: {}
        duration: "30m"
EOT
}

resource "kubectl_manifest" "app_autoscaler_release_runnerset" {
  yaml_body = <<EOT
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerSet
metadata:
  name: autoscaler-arc-runnerset
  namespace: actions-runner-system
spec:
  repository: cloudfoundry/app-autoscaler-release
  selector:
   matchLabels:
     app: autoscaler-arc-workers
  serviceName: autoscaler-arc-service
  template:
    metadata:
      labels:
        app: autoscaler-arc-workers
    spec:
      tolerations:
      - effect: NoSchedule
        key: github-arc-workers
        operator: Equal
        value: "true"
      containers:
      - name: docker
        volumeMounts:
        - name: var-lib-docker
          mountPath: /var/lib/docker
  volumeClaimTemplates:
  - metadata:
      name: var-lib-docker
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 20Gi
      storageClassName: premium-rwo

EOT

depends_on = [google_container_node_pool.github_arc ]

}