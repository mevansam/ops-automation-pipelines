#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

[[ $# -lt 3 ]] && (
    echo -e "Usage: ./backup-rmq.sh <DEPLOYMENT_PATTERN> <MYSQL_PROXY_NAME> <ARCHIVE_DEST_NAME> [ <CRED_PREFIX> ]"
    exit 1
)

source backup-timestamp/metadata
source job-session/env

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

deployment=$1
rmq_proxy=$2
archive_dest_name=$3
cred_prefix=$4

rmq_proxy_ip=$(bosh::get_job_vm_ip "$deployment" "$rmq_proxy" 0)

curl -s -k -OL http://$rmq_proxy_ip:15672/cli/rabbitmqadmin
chmod 0755 rabbitmqadmin

rmq_config_export=backup/$BACKUP_TIMESTAMP/$archive_dest_name/rmq_config_export.cfg
mkdir -p $(dirname $rmq_config_export)

rmq_user_var=$(eval echo "\$${cred_prefix}RMQ_ADMIN_USER")
rmq_password_var=$(eval echo "\$${cred_prefix}RMQ_ADMIN_PASSWORD")

set +e

# Backup Rabbit Configuration
./rabbitmqadmin \
    -H $rmq_proxy_ip \
    -u $rmq_user_var \
    -p $rmq_password_var \
    export $rmq_config_export

if [[ $? -ne 0 ]]; then
    echo "Export of RabbitMQ configuration failed. Export file contents are:"
    cat $rmq_config_export
    exit 1
fi

gzip $rmq_config_export
backup::upload backup $BACKUP_TYPE $BACKUP_TARGET
