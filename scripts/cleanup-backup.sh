#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

source backup-timestamp/metadata

cp -r backup-timestamp/name restore-timestamp/
cp -r backup-timestamp/metadata restore-timestamp/

grep -q "^RESTORE_TIMESTAMP=" restore-timestamp/metadata && \
    sed -i "s|^RESTORE_TIMESTAMP=.*$|RESTORE_TIMESTAMP=$BACKUP_TIMESTAMP|" restore-timestamp/metadata || \
    echo "RESTORE_TIMESTAMP=$BACKUP_TIMESTAMP" >> restore-timestamp/metadata

BACKUP_AGE=${1:-7}
backup::cleanup $BACKUP_AGE $BACKUP_TYPE $BACKUP_TARGET

set +e +x
