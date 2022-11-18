resource "null_resource" "fly_trigger_job" {
    triggers = {
        random_id = random_id.credhub_cli.hex
    }

    provisioner "local-exec" {
        command = <<EOF
          echo ">> Running fly trigger-job"
          fly -t ${var.fly_target} trigger-job -j ${var.pipeline}/${var.pipeline_job} -w
        EOF
    }

    depends_on = [ concourse_pipeline.e2e-test ]
}