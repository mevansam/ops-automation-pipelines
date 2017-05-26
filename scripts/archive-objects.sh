#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

[[ $# -ne 5 ]] && (
    echo -e "Usage: ./backup-persistent-storage.sh <DEPLOYMENT_PATTERN> <INSTANCE_PATTERN> <ARCHIVE_ROOT_PATH> <ARCHIVE_OBJECTS> <ARCHIVE_DEST_NAME>"
    exit 1
)

source backup-timestamp/metadata

opsman::download_bosh_ca_cert $OPSMAN_HOST $OPSMAN_SSH_USER $OPSMAN_SSH_PASSWD

opsman::login_client $OPSMAN_HOST $PCFOPS_CLIENT $PCFOPS_SECRET $OPSMAN_PASSPHRASE
bosh::login_client root_ca_certificate $(opsman::get_director_ip) $PCFOPS_CLIENT $PCFOPS_SECRET

DEPLOYMENT_PATTERN=$1
INSTANCE_PATTERN=$2
ARCHIVE_ROOT_PATH=$3
ARCHIVE_OBJECTS=$4
ARCHIVE_DEST_NAME=$5

JOB_INSTANCE_IP=$(opsman::get_job_vm_ip "$DEPLOYMENT_PATTERN" "$INSTANCE_PATTERN" 0)

# Enable passwordless sudo on job instance to backup
function cleanup_instance {

    # Reset passwordless sudo on exit
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vcap@$JOB_INSTANCE_IP -- <<EOF
[[ -e /etc/sudoers.orig ]] && sudo mv /etc/sudoers.orig /etc/sudoers
EOF
}
trap cleanup_instance EXIT

PREPARE_INSTANCE=$(cat <<END
[[ -e /etc/sudoers.orig ]] || cp /etc/sudoers /etc/sudoers.orig
grep "^vcap " /etc/sudoers || echo -e "\nvcap ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
END
)
bosh::ssh "$DEPLOYMENT_PATTERN" "$INSTANCE_PATTERN" "$PREPARE_INSTANCE"

# Archive and compress blobs and stream to local backup location

ARCHIVE_DEST_PATH=backup/$BACKUP_TIMESTAMP/$ARCHIVE_DEST_NAME
mkdir -p $ARCHIVE_DEST_PATH

for b in $(echo "$ARCHIVE_OBJECTS"); do
    echo "Backing up blobs: $b"
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vcap@$JOB_INSTANCE_IP -- \
        "sudo su -c 'cd $ARCHIVE_ROOT_PATH && tar czvf - $b'" > $ARCHIVE_DEST_PATH/$b.tgz
done

# Upload blobs to storage

backup::upload backup $BACKUP_TYPE $BACKUP_TARGET $BACKUP_SSH_HOST $BACKUP_SSH_USER $BACKUP_SSH_PASSWORD
