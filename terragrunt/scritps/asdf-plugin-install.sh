#!/usr/bin/env bash
set -euo pipefail

if [ ! $(which asdf) ]
  then
    echo "ERROR: asdf not found, please install it: https://asdf-vm.com/guide/getting-started.html"
    exit 1
fi

echo
echo ">> Add required plugin as defined in asdf .tool-versions"
for p in $(cat .tool-versions | awk '{ print $1 }')
    do asdf plugin add $p &&  asdf install $p
done
echo

echo ">> Show installed asdf plugins"
asdf current
