#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/bosh-func.sh
iaas::initialize

[[ -n "$TRACE" ]] && set -x
set -e

[[ $# -ne 5 ]] && (
    echo -e "Usage: ./create-object-links.sh <DEPLOYMENT_PATTERN> <INSTANCE_PATTERN> <ROOT_PATH> <OBJECTS> <DEST>"
    exit 1
)

source job-session/env

bosh::login_client "$CA_CERT" $BOSH_HOST $PCFOPS_CLIENT $PCFOPS_SECRET

deployment_pattern=$1
instance_pattern=$2
root_path=$3
objects=$4
destination=$5

create_object_links=$(cat <<END
#!/bin/bash
set -e

pushd $root_path
rm -fr $destination

for o in \$(echo "$objects"); do
    for d in \$(find \$o -type d); do
        mkdir -p $destination/\$d
    done
    for f in \$(find \$o -type f); do
        ln \$f $destination/\$f
    done
done

popd
END
)
bosh::ssh "$deployment_pattern" "$instance_pattern" "$create_object_links"
