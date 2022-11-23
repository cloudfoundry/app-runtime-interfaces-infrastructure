resource "kubernetes_namespace" "github_actions_runners" {
  metadata {
    name = "github-actions-runners"
  }
}

# resource "kubertnetes_manifest" "runner_deployment" {
#   manifest = {
#     apiVersion = "actions.summerwind.dev/v1alpha1"
#     kind       = "RunnerDeployment"
#     metadata = {
#       name      = "actions-runner"
#       namespace = "github-actions-runners"

#       spec = {
#         template = {
#           spec = {
#             repository = "summerwind/actions-runner-controller"
#           }
#           tolerations = {
#             key      = "github-arc-workers"
#             operator = "Equal"
#             value    = "true"
#             effect   = "NoSchedule"

#           }
#         }
#       }
#     }
#   }
#   depends_on = [kubernetes_namespace.github_actions_runners]
# }