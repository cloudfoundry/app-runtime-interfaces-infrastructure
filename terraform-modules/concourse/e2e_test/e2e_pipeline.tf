 resource "concourse_pipeline" "e2e-test" {

   team_name     = var.fly_team
   pipeline_name = var.pipeline

   is_exposed = var.pipeline_exposed
   is_paused  = false

   pipeline_config        = templatefile("pipeline.yml",
    {  pipeline_job = "${var.pipeline_job}",
       credhub-test-secret-name = "${var.credhub-test-secret-prefix}-${random_id.credhub_cli.hex}"
       credhub-test-secret-value = "${var.credhub-test-secret-prefix}-${random_id.credhub_cli.hex}-value"
       credhub-test-secret-path = "${var.credhub-test-secret-path}"
        })
   pipeline_config_format = "yaml"

   depends_on = [ kubernetes_job.credhub_cli ]
 }

