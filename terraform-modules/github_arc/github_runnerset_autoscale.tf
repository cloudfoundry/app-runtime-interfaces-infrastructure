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
  namespace: actions-runner-workers
spec:
  minReplicas: 0
  maxReplicas: 16
  scaleTargetRef:
    kind: RunnerSet
    name: autoscaler-arc-runnerset
  scaleUpTriggers:
    - githubEvent:
        workflowJob: {}
        duration: "10m"
  scaleDownDelaySecondsAfterScaleOut: 30
EOT
}

resource "kubectl_manifest" "app_autoscaler_release_runnerset" {
  yaml_body = <<EOT
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerSet
metadata:
  name: autoscaler-arc-runnerset
  namespace: actions-runner-workers
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
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: cloud.google.com/gke-nodepool
                operator: In
                values:
                - "github-arc-workers"
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
      - name: runner
        resources:
          requests:
            #cpu: "1600m" #schedules 4 runners on 8 core
            cpu: "800m"
        #     memory: "3.0Gi"
        #  limits:
        #    cpu: "800m"
        #    memory: "3.0Gi"

  volumeClaimTemplates:
  - metadata:
      name: var-lib-docker
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 20Gi
      storageClassName: arc-regional

EOT

depends_on = [google_container_node_pool.github_arc ]

}