resource "kubernetes_namespace" "github_actions_runners" {
  metadata {
    name = "actions-runner-workers"
  }
}

# resource "kubectl_manifest" "runnerset_autoscaler_ingress" {
#   yaml_body = <<EOT
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: actions-runner-controller-github-webhook-server
#   namespace: actions-runner-system
#   annotations:
#     kubernetes.io/ingress.class: nginx
#     nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
# spec:
#   tls:
#   - hosts:
#     - concourse-test.app-runtime-interfaces.ci.cloudfoundry.org
# #    secretName: your-tls-secret-name
#   rules:
#     - http:
#         paths:
#           - path: /actions-runner-controller-github-webhook-server
#             pathType: Prefix
#             backend:
#               service:
#                 name: actions-runner-controller-github-webhook-server
#                 port:
#                   number: 80
# EOT
# }

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
# resource "kubectl_manifest" "runner_deployment" {
#   yaml_body = <<EOT
# apiVersion: actions.summerwind.dev/v1alpha1
# kind: RunnerSet
# metadata:
#   name: autoscaler-arc-runnerset
#   namespace: actions-runner-workers
# spec:
#   repository: cloudfoundry/app-autoscaler-release
#   selector:
#    matchLabels:
#      app: autoscaler-arc-workers
#   replicas: 10
#   serviceName: autoscaler-arc-service
#   template:
#     metadata:
#       labels:
#         app: autoscaler-arc-workers
#     spec:
#       tolerations:
#       - effect: NoSchedule
#         key: github-arc-workers
#         operator: Equal
#         value: "true"
#       containers:
#       - name: docker
#         volumeMounts:
#         - name: var-lib-docker
#           mountPath: /var/lib/docker
#   volumeClaimTemplates:
#   - metadata:
#       name: var-lib-docker
#     spec:
#       accessModes:
#       - ReadWriteOnce
#       resources:
#         requests:
#           storage: 20Gi
#       storageClassName: premium-rwo

# EOT

# depends_on = [google_container_node_pool.github_arc ]

# }