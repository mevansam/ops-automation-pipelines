#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

[[ $# -ne 5 ]] && (
    echo -e "Usage: ./archive-objects.sh <DEPLOYMENT_PATTERN> <INSTANCE_PATTERN> <ARCHIVE_ROOT_PATH> <ARCHIVE_OBJECTS> <ARCHIVE_DEST_NAME>"
    exit 1
)

source backup-timestamp/metadata
source job-session/env

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

deployment_pattern=$1
instance_pattern=$2
archive_root_path=$3
archive_objects=$4
archive_dest_name=$5

job_instance_ip=$(bosh::get_job_vm_ip "$deployment_pattern" "$instance_pattern" 0)

# Enable passwordless sudo on job instance to backup
function cleanup_instance {

    # Reset passwordless sudo on exit
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vcap@$job_instance_ip -- <<EOF
[[ -e /etc/sudoers.orig ]] && sudo mv /etc/sudoers.orig /etc/sudoers
EOF
}
trap cleanup_instance EXIT

prepare_instance=$(cat <<END
[[ -e /etc/sudoers.orig ]] || cp /etc/sudoers /etc/sudoers.orig
grep "^vcap " /etc/sudoers || echo -e "\nvcap ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
END
)
bosh::ssh "$deployment_pattern" "$instance_pattern" "$prepare_instance"

# Archive and compress blobs and stream to local backup location

archive_dest_path=backup/$BACKUP_TIMESTAMP/$archive_dest_name
mkdir -p $archive_dest_path

for b in $(echo "$archive_objects"); do
    echo "Backing up blobs: $b"
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vcap@$job_instance_ip -- \
        "sudo su -c 'cd $archive_root_path && tar czvf - $b'" > $archive_dest_path/$b.tgz
done

# Upload blobs to storage

backup::upload backup $BACKUP_TYPE $BACKUP_TARGET
