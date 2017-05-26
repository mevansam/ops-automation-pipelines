#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

[[ $# -ne 5 ]] && (
    echo -e "Usage: ./create-object-links.sh <DEPLOYMENT_PATTERN> <INSTANCE_PATTERN> <ROOT_PATH> <OBJECTS> <DEST>"
    exit 1
)

opsman::download_bosh_ca_cert $OPSMAN_HOST $OPSMAN_SSH_USER $OPSMAN_SSH_PASSWD

opsman::login_client $OPSMAN_HOST $PCFOPS_CLIENT $PCFOPS_SECRET $OPSMAN_PASSPHRASE
bosh::login_client root_ca_certificate $(opsman::get_director_ip) $PCFOPS_CLIENT $PCFOPS_SECRET

DEPLOYMENT_PATTERN=$1
INSTANCE_PATTERN=$2
ROOT_PATH=$3
OBJECTS=$4
DESTINATION=$5

JOB_INSTANCE_IP=$(opsman::get_job_vm_ip "$DEPLOYMENT_PATTERN" "$INSTANCE_PATTERN" 0)

CREATE_OBJECT_LINKS=$(cat <<END
#!/bin/bash
set -e

pushd $ROOT_PATH
rm -fr $DESTINATION

for o in \$(echo "$OBJECTS"); do
    for d in \$(find \$o -type d); do
        mkdir -p $DESTINATION/\$d
    done
    for f in \$(find \$o -type f); do
        ln \$f $DESTINATION/\$f
    done
done

popd
END
)
bosh::ssh "$DEPLOYMENT_PATTERN" "$INSTANCE_PATTERN" "$CREATE_OBJECT_LINKS"
