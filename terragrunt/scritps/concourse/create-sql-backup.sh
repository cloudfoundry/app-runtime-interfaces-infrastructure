#!/usr/bin/env bash
set -euo pipefail

if [ ! -s "./config.yaml" ]; then
    echo "ERROR: Please 'cd' to your folder with config.yaml and run this script again."
    exit 1
fi

project="$(yq .project config.yaml)"
sql_instance="$(yq .gke_name config.yaml)-concourse"
epoch_date="$(date +%s)"

gcloud_format=( --format="table[box](windowStartTime, id, backupKind, status, type, description)" )

read -p "About to create CloudSQL backup for an instance $sql_instance. Please confirm with 'yes' to continue: " -r
 echo
  if [[ ! "$REPLY" == "yes" ]]
  then
      echo "Canceling"
      exit 1
  fi

echo ">> Current backups list"
gcloud sql backups list -i "${sql_instance}" --project "${project}" "${gcloud_format[@]}"
echo


echo ">> Creating the backup with description scripted-${epoch_date}"
gcloud sql backups create --instance="${sql_instance}" --description scripted-"${epoch_date}" --project "$project"
echo

echo ">> New backups list"
gcloud sql backups list -i "${sql_instance}" --project "$project" "${gcloud_format[@]}"
echo

echo ">> FINISHED | Note: please delete ON_DEMAND backup manually"