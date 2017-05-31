#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

source job-session/env

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

deployment_prefix=$1
job_prefix=$2/
action=$3

case $action in
    start)
        bosh::ssh $deployment_prefix $job_prefix "monit start all"
        bosh::enable_resurrection $deployment_prefix
        ;;
    stop)
        bosh::disable_resurrection $deployment_prefix
        bosh::ssh $deployment_prefix $job_prefix "monit stop all"
        ;;
    *)
        echo "Only 'start' and 'stop' actions are supported for the job."
        exit 1
esac
