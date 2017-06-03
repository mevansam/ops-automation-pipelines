#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

[[ $# -lt 3 ]] && (
    echo -e "Usage: ./backup-mysql.sh <DEPLOYMENT_PATTERN> <MYSQL_PROXY_NAME> <ARCHIVE_DEST_NAME> [ <CRED_PREFIX> ]"
    exit 1
)

source backup-timestamp/metadata
source job-session/env

mysql_port=${MYSQL_PORT:-3306}

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

deployment=$1
mysql_proxy=$2
archive_dest_name=$3
cred_prefix=$4

mysql_proxy_ip=$(bosh::get_job_vm_ip "$deployment" "$mysql_proxy" 0)

all_databases_dump=backup/$BACKUP_TIMESTAMP/$archive_dest_name/all_databases.sql
mkdir -p $(dirname $all_databases_dump)

mysql_user_var=$(eval echo "\$${cred_prefix}MYSQL_USER")
mysql_password_var=$(eval echo "\$${cred_prefix}MYSQL_PASSWORD")

mysqldump --host $mysql_proxy_ip --port $mysql_port \
    --user=$mysql_user_var --password=$mysql_password_var \
    --all-databases > $all_databases_dump

grep "\-\- Dump completed on $(date +'%Y-%m-%d')" $all_databases_dump
gzip $all_databases_dump

backup::upload backup $BACKUP_TYPE $BACKUP_TARGET
