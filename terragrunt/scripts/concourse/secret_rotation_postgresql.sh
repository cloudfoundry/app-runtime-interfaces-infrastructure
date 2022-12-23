#!/usr/bin/env bash
set -euo pipefail

if [ ! -s "./config.yaml" ]; then
    echo "ERROR: Please 'cd' to your folder with config.yaml and run this script again."
    exit 1
fi

tg_secret_rotation_params=( --terragrunt-config=rotate.hcl --terragrunt-source-update --auto-approve)

project="$(yq .project config.yaml)"
zone="$(yq .zone config.yaml)"
gke_name="$(yq .gke_name config.yaml)"

secrets=(concourse-postgresql-password credhub-postgresql-password uaa-postgresql-password)

deployments=(concourse-web concourse-worker credhub uaa)

if [[ ! "$gke_name" =~ .*test*. ]]
then
  read -p "Detected a non-test environment. Please confirm with 'yes' to continue: " -r
  echo
  if [[ ! "$REPLY" == "yes" ]]
  then
      echo "Canceling"
      exit 1
  fi
fi

echo ">> Fetching kubectl config for cluster: ${gke_name} | project: ${project} | zone: ${zone}"

gcloud container clusters get-credentials ${gke_name} --zone ${zone} --project ${project}

cat <<-EOF

Invoking secrets rotation. The following actions will be applied:

  - postgresql k8s secrets: delete (in concourse namespace)
  - secretgen controller: pod restart to refresh new sql passwords in k8s secrets
  - cloud sql users: passwords sync from k8s secrets for respective sql users
  - application pods restart to refresh new config:
    - concourse-web
    - concourse-worker (k8s nodepool autoscaling will be triggered)
    - credhub
    - uaa

EOF

echo ">> Show existing secrets and their age"
kubectl -n concourse get secrets | grep postgres ||true
echo

read -p "Please confirm with 'yes' to continue: " -r
echo
if [[ ! "$REPLY" == "yes" ]]
then
    echo "Canceling"
    exit 1
fi

echo ">> Deleting existing postgresql secrets"
for secret in "${secrets[@]}"
do
  kubectl delete secret -n concourse $secret ||true
done
echo

echo ">> Restarting secretgen controller pod [1/2]: scale down to 0 replicas"
kubectl scale deploy -n secretgen-controller secretgen-controller --replicas=0
echo

echo ">> Restarting secretgen controller pod [1/2]: scale back up to 1 replicas"
kubectl scale deploy -n secretgen-controller secretgen-controller --replicas=1
echo

echo ">> Wating to confirm secretgen controllers replicas=1"
kubectl wait deployment -n secretgen-controller secretgen-controller --for=jsonpath='{.spec.replicas}'=1 --timeout=30s
echo

echo ">> Waiting for secrets"
for secret in "${secrets[@]}"
do
 while ! kubectl get secret -n concourse $secret
  do
   echo "Waiting for secret: $secret"
   sleep 5
  done
done
echo

echo ">> Wait for secrets update from secretgen controller"
  kubectl -n concourse wait --for=jsonpath='{.metadata.managedFields[0].operation}'="Update" --timeout=30s \
           secret/"${secrets[0]}" \
           secret/"${secrets[1]}" \
           secret/"${secrets[2]}"
echo

echo ">> Show new postgresql secrets and their age"
kubectl -n concourse get secrets | grep postgres
echo

echo ">> Apply terragrunt (with resource show) to synchronise kubernetes secrets with CloudSQL Users"
( cd ./secret_rotation_postgresql && terragrunt apply "${tg_secret_rotation_params[@]}" )
echo

echo "Scaling down deployments: ${deployments[*]}"

for deployment in "${deployments[@]}"
do
  kubectl scale deploy -n concourse "${deployment}" --replicas=0
done
echo

echo "Scaling up deployments: ${deployments[*]}"

for deployment in "${deployments[@]}"
do
  kubectl scale deploy -n concourse "${deployment}" --replicas=1
done
echo

echo ">> Wait for deployments available"
  kubectl -n concourse wait --for=condition=available --timeout=200s \
           deployment/"${deployments[0]}" \
           deployment/"${deployments[1]}" \
           deployment/"${deployments[2]}" \
           deployment/"${deployments[3]}"
echo

echo "Completed"