#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

source backup-timestamp/metadata
source job-session/env

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

echo "Backing via Bosh Backup and Restore utility..."


backup::upload backup $BACKUP_TYPE $BACKUP_TARGET $BACKUP_SSH_HOST $BACKUP_SSH_USER $BACKUP_SSH_PASSWORD
