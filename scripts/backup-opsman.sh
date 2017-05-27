#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

if [[ -n "$OPSMAN_SSH_PASSWD" ]]; then
    SSH_PASS=sshpass -p$OPSMAN_SSH_PASSWD
fi

source backup-timestamp/metadata
source job-session/env

INSTALLATION_ZIP=$(pwd)/backup/$BACKUP_TIMESTAMP/opsman/installation.zip
mkdir -p $(dirname $INSTALLATION_ZIP)

curl -s -k "$opsman_url/api/v0/installation_asset_collection" \
  -H "Authorization: Bearer $opsman_token" \
  -X GET -o $INSTALLATION_ZIP &
export_pid=$!

$SSH_PASS ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OPSMAN_SSH_USER@$OPSMAN_HOST -- \
    "sudo su -c 'cd /var/tempest/ && tar cvf - stemcells'" | tar xv -C .

wait $export_pid

set +e
file $INSTALLATION_ZIP | grep 'ASCII text' >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    cat $INSTALLATION_ZIP
    exit 1
fi
set -e

zip -ur $INSTALLATION_ZIP stemcells/

backup::upload backup $BACKUP_TYPE $BACKUP_TARGET $BACKUP_SSH_HOST $BACKUP_SSH_USER $BACKUP_SSH_PASSWORD
