#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

source backup-timestamp/metadata
source job-session/env

MYSQL_PORT=${MYSQL_PORT:-3306}

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

deployment=$1
mysql_proxy_ip=$(bosh::get_job_vm_ip "$deployment" mysql_proxy 0)

all_databases_dump=backup/$BACKUP_TIMESTAMP/mysql/all_databases.sql
mkdir -p $(dirname $all_databases_dump)

mysqldump --host $mysql_proxy_ip --port $MYSQL_PORT \
    --user=root --password=$MYSQL_PASSWORD \
    --all-databases > $all_databases_dump

grep "\-\- Dump completed on $(date +'%Y-%m-%d')" $all_databases_dump
gzip $all_databases_dump

backup::upload backup $BACKUP_TYPE $BACKUP_TARGET
