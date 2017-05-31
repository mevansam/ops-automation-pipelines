#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

if [[ -n "$OPSMAN_SSH_PASSWD" ]]; then
    ssh_pass=sshpass -p$OPSMAN_SSH_PASSWD
fi

source backup-timestamp/metadata
source job-session/env

installation_zip=$(pwd)/backup/$BACKUP_TIMESTAMP/opsman/installation.zip
mkdir -p $(dirname $installation_zip)

curl -s -k "$opsman_url/api/v0/installation_asset_collection" \
  -H "Authorization: Bearer $opsman_token" \
  -X GET -o $installation_zip &
export_pid=$!

$ssh_pass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OPSMAN_SSH_USER@$OPSMAN_HOST -- \
    "sudo su -c 'cd /var/tempest/ && tar cvf - stemcells'" | tar xv -C .

wait $export_pid

set +e
file $installation_zip | grep 'ASCII text' >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    cat $installation_zip
    exit 1
fi
set -e

zip -ur $installation_zip stemcells/

backup::upload backup $BACKUP_TYPE $BACKUP_TARGET $BACKUP_SSH_HOST $BACKUP_SSH_USER $BACKUP_SSH_PASSWORD
