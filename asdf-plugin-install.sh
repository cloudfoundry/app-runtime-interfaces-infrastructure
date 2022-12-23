#!/usr/bin/env bash
set -euo pipefail

if [ ! $(which asdf) ]
  then
    echo "ERROR: asdf not found, please install it: https://asdf-vm.com/guide/getting-started.html"
    exit 1
fi

if [ ! -s .tool-versions ]
  then
    echo "ERROR: .tools-versions not found in root directory"
    exit 1
fi

echo
echo ">> Add required plugin as defined in asdf .tool-versions"
for p in $(cat .tool-versions | awk '{ print $1 }')
    do
       asdf plugin add "${p}" || true
done
echo

echo ">> Install all plugins defined in .tool-versions"
asdf install
echo

echo ">> Show installed asdf plugins"
asdf current
