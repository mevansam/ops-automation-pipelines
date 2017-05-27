#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

source job-session/env

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

DEPLOYMENT_PREFIX=$1
JOB_PREFIX=$2/
ACTION=$3

case $ACTION in
    start)
        bosh::ssh $DEPLOYMENT_PREFIX $JOB_PREFIX "monit start all"
        bosh::enable_resurrection $DEPLOYMENT_PREFIX
        ;;
    stop)
        bosh::disable_resurrection $DEPLOYMENT_PREFIX
        bosh::ssh $DEPLOYMENT_PREFIX $JOB_PREFIX "monit stop all"
        ;;
    *)
        echo "Only 'start' and 'stop' actions are supported for the job."
        exit 1
esac
