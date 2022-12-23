#!/usr/bin/env bash
set -euo pipefail

# Enter you github repository access token
token=""

if [ -z "${token}" ]; then
  echo "ERROR: Please enter your credentials on the top of this script"
  exit 1
fi

if [ ! -s "./config.yaml" ]; then
    echo "ERROR: Please 'cd' to your folder with config.yaml and run this script again."
    exit 1
fi

secret_name="$(yq .arc_github_access_token_name config.yaml)"
secret_region="$(yq .region config.yaml)"
project="$(yq .project config.yaml)"

echo "Creating the gcp secret ${secret_name} in project ${project} within region ${secret_region}..."

gcloud secrets create "${secret_name}" \
 --replication-policy="user-managed" \
 --locations="${secret_region}" \
 --project="${project}"

echo "Creating secret version..."

printf "%s" ${token} | \
gcloud secrets versions add "${secret_name}" --data-file=- --project="${project}"

echo "Done"