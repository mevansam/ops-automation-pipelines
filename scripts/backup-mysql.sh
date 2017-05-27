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

PRODUCT_TYPE=$1
MYSQL_PROXY_IP=$(opsman::get_job_vm_ip ${PRODUCT_TYPE} 'mysql_proxy' 0)
MYSQL_PORT=${MYSQL_PORT:-3306}

MYSQL_USER=$(opsman::get_product_credential $PRODUCT_TYPE mysql_admin_credentials | jq -r .credential.value.identity)
MYSQL_PASSWORD=$(opsman::get_product_credential $PRODUCT_TYPE mysql_admin_credentials | jq -r .credential.value.password)

ALL_DATABASES_DUMP=backup/$BACKUP_TIMESTAMP/mysql/all_databases.sql
mkdir -p $(dirname $ALL_DATABASES_DUMP)

mysqldump --host $MYSQL_PROXY_IP --port $MYSQL_PORT \
    --user=root --password=$MYSQL_PASSWORD \
    --all-databases > $ALL_DATABASES_DUMP

grep "\-\- Dump completed on $(date +'%Y-%m-%d')" $ALL_DATABASES_DUMP
gzip $ALL_DATABASES_DUMP

backup::upload backup $BACKUP_TYPE $BACKUP_TARGET
