#!/usr/bin/env bash
set -euo pipefail

if [ ! -s "./config.yaml" ]; then
    echo "ERROR: Please 'cd' to your folder with config.yaml and run ../scripts/secret_rotation_postgresql.sh"
    exit 1
fi

project="$(yq .project config.yaml)"
zone="$(yq .zone config.yaml)"
gke_name="$(yq .gke_name config.yaml)"

secrets=(concourse-postgresql-password credhub-postgresql-password uaa-postgresql-password)

#TODO: grep clustername - if no 'test' warn the cluster appears to be production, ask for confirmation

echo ">> Fetching kubectl config for cluster: ${gke_name} | project: ${project} | zone: ${zone}"
gcloud container clusters get-credentials ${gke_name} --zone ${zone} --project ${project}

#TODO: show cluster name and ask to confirm listing what will happen
# - postgresql k8s secrets: delete (in concourse namespace)
# - secretgen controller: pod restart to refresh new sql passwords in k8s secrets
# - cloud sql users: passwords sync from k8s secrets for respective sql users
# - application pods restart to refresh new config:
#   - concourse-web
#   - concourse-worker (k8s nodepool autoscaling will be triggered)
#   - credhub
#   - uaa-deployment

echo ">> Show existing secrets and their age"
kubectl -n concourse get secrets | grep postgres ||true

echo ">> Deleting existing postgresql secrets"
for secret in "${secrets[@]}"
do
  kubectl delete secret -n concourse $secret ||true
done

echo ">> Restarting secretgen controller pod [1/2]: scale down to 0 replicas"
kubectl scale deploy -n secretgen-controller secretgen-controller --replicas=0

echo ">> Restarting secretgen controller pod [1/2]: scale back up to 1 replica)"
kubectl scale deploy -n secretgen-controller secretgen-controller --replicas=1

echo ">> Wating to confirm secretgen controllers replicas=1"
kubectl wait deployment -n secretgen-controller secretgen-controller --for=jsonpath='{.spec.replicas}'=1 --timeout=30s

echo ">> Waiting for secrets"
for secret in "${secrets[@]}"
do

 while ! kubectl get secret -n concourse $secret
  do
   echo "Waiting for secret: $secret"
   sleep 5
  done
done

echo ">> Wait for secrets update from secretgen controller"
  kubectl -n concourse wait --for=jsonpath='{.metadata.managedFields[0].operation}'="Update" --timeout=30s \
           secret/"${secrets[0]}" \
           secret/"${secrets[1]}" \
           secret/"${secrets[2]}" \

echo ">> Show new postgresql secrets and their age"
kubectl -n concourse get secrets | grep postgres

# TODO: terragrunt invoke sql passwords update

# TODO: kubectl scale down deployments to 0 and 1

# TODO: kubectl wait for deployments