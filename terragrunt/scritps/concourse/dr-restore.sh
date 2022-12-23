#!/usr/bin/env bash
set -euo pipefail
if [ ! -s "./config.yaml" ]; then
    echo "ERROR: Please 'cd' to your folder with config.yaml and run this script again."
    exit 1
fi

echo; echo ">> Executing dr restore. You will be asked to confirm changes to apply."; echo

echo "[1/5] Terragrunt apply for infra only"
( cd ./infra && terragrunt apply --terragrunt-source-update )
echo


echo "[2/5] Terragrunt apply for backend only"
( cd ./backend && terragrunt apply --terragrunt-source-update )
echo


echo "[3/5] Carvel might not learn new state during the recovery an we need to retrigger it."
( cd ./backend && terragrunt apply --terragrunt-source-update )
echo


echo "[4/5] Restore credhub encryption key key and populate new sql users passwords from secretgen"
( cd ./dr_restore && terragrunt apply --terragrunt-config=credhub_sql_passwords.hcl --terragrunt-source-update )
echo


echo "[5/5] Terragrunt apply for app only"
( cd ./app && terragrunt apply --terragrunt-source-update )
echo


echo "-- DR recovery completed"