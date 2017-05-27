#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

cp -r backup-metadata/name backup-timestamp/
cp -r backup-metadata/metadata backup-timestamp/

TIMESTAMP=$(date +%Y%m%d%H%M%S)
grep -q "^BACKUP_TIMESTAMP=" backup-timestamp/metadata && \
    sed -i "s|^BACKUP_TIMESTAMP=.*$|BACKUP_TIMESTAMP=$TIMESTAMP|" backup-timestamp/metadata || \
    echo "BACKUP_TIMESTAMP=$TIMESTAMP" >> backup-timestamp/metadata

# Clean up Ops Manager /tmp folder to free up space for export and restart the service

if [[ -n "$OPSMAN_SSH_PASSWD" ]]; then
    SSH_PASS=sshpass -p$OPSMAN_SSH_PASSWD
fi

$SSH_PASS ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OPSMAN_SSH_USER@$OPSMAN_HOST -- \
    "sudo su -c 'service tempest-web stop; rm -fr /tmp/*; service tempest-web start'"

opsman::login_client $OPSMAN_HOST $PCFOPS_CLIENT $PCFOPS_SECRET $OPSMAN_PASSPHRASE
opsman::download_bosh_ca_cert $OPSMAN_HOST $OPSMAN_SSH_USER $OPSMAN_SSH_PASSWD

echo "opsman_url=$opsman_url" > job-session/env
echo "opsman_token=$opsman_token" >> job-session/env
echo "BOSH_HOST=$(opsman::get_director_ip)" >> job-session/env
echo "CA_CERT='$(cat root_ca_certificate)'" >> job-session/env

set +e +x
