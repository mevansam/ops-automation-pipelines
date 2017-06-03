#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
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
    ssh_pass=sshpass -p$OPSMAN_SSH_PASSWD
fi

$ssh_pass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OPSMAN_SSH_USER@$OPSMAN_HOST -- \
    "sudo su -c 'service tempest-web stop; rm -fr /tmp/*; service tempest-web start'"

opsman::login_client $OPSMAN_HOST $PCFOPS_CLIENT $PCFOPS_SECRET $OPSMAN_PASSPHRASE
opsman::download_bosh_ca_cert $OPSMAN_HOST $OPSMAN_SSH_USER $OPSMAN_SSH_PASSWD
opsman::wait_for_last_apply_to_finish

bosh_host=$(opsman::get_director_ip)
ert_mysql_user=$(opsman::get_product_credential cf- mysql_admin_credentials | jq -r .credential.value.identity)
ert_mysql_password=$(opsman::get_product_credential cf- mysql_admin_credentials | jq -r .credential.value.password)
mysql_user=$(opsman::get_product_credential p-mysql- mysql_admin_password | jq -r .credential.value.identity)
mysql_password=$(opsman::get_product_credential p-mysql- mysql_admin_password | jq -r .credential.value.password)
rmq_admin_user=$(opsman::get_product_credential p-rabbitmq- server_admin_credentials | jq -r .credential.value.identity)
rmq_admin_password=$(opsman::get_product_credential p-rabbitmq- server_admin_credentials | jq -r .credential.value.password)

echo "opsman_url=$opsman_url" > job-session/env
echo "opsman_token=$opsman_token" >> job-session/env
echo "BOSH_HOST=$bosh_host" >> job-session/env
echo "CA_CERT='$(cat root_ca_certificate)'" >> job-session/env
echo "ERT_MYSQL_USER='$ert_mysql_user'" >> job-session/env
echo "ERT_MYSQL_PASSWORD='$ert_mysql_password'" >> job-session/env
echo "MYSQL_USER='$mysql_user'" >> job-session/env
echo "MYSQL_PASSWORD='$mysql_password'" >> job-session/env
echo "RMQ_ADMIN_USER='$rmq_admin_user'" >> job-session/env
echo "RMQ_ADMIN_PASSWORD='$rmq_admin_password'" >> job-session/env

set +e +x
