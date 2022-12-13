resource "kubernetes_storage_class_v1" "arc_regional" {
metadata {
  name = "${var.team_name}-arc-regional"
}
storage_provisioner = "pd.csi.storage.gke.io"
reclaim_policy = "Delete"
parameters = {
  "type" = var.gke_arc_runner_storage_type
  "replication-type" = "regional-pd"
}
volume_binding_mode = "WaitForFirstConsumer"
allowed_topologies {
  match_label_expressions {
    key = "topology.gke.io/zone"
    values = [
        "${var.region}-a",
        "${var.region}-b"
    ]
  }
}
}