#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

source backup-timestamp/metadata

opsman::download_bosh_ca_cert $OPSMAN_HOST $OPSMAN_SSH_USER $OPSMAN_SSH_PASSWD

opsman::login_client $OPSMAN_HOST $PCFOPS_CLIENT $PCFOPS_SECRET $OPSMAN_PASSPHRASE
bosh::login_client root_ca_certificate $(opsman::get_director_ip) $PCFOPS_CLIENT $PCFOPS_SECRET

echo "Backing via Bosh Backup and Restore utility..."


backup::upload backup $BACKUP_TYPE $BACKUP_TARGET $BACKUP_SSH_HOST $BACKUP_SSH_USER $BACKUP_SSH_PASSWORD
