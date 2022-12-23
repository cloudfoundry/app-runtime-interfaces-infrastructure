#!/usr/bin/env bash
set -euo pipefail

if [ ! -s "./config.yaml" ]; then
    echo "ERROR: Please 'cd' to your folder with config.yaml and run this script again."
    exit 1
fi

secret_name="$(yq .gke_name config.yaml)-arc-webhook-server-token"
secret_region="$(yq .region config.yaml)"
project="$(yq .project config.yaml)"

echo "Genererating random server token"
arc_webhook_server_token="$(python3 -c "import secrets; print( secrets.token_hex(35), end='' );" )"

echo "Creating the gcp secret ${secret_name} in project ${project} within region ${secret_region}..."

gcloud secrets create "${secret_name}" \
 --replication-policy="user-managed" \
 --locations="${secret_region}" \
 --project="${project}"

echo "Creating secret version..."

printf "%s" "${arc_webhook_server_token}" | \
gcloud secrets versions add "${secret_name}" --data-file=- --project="${project}"

echo "Done"