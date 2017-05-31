#!/bin/bash

source ~/scripts/iaas-func.sh
source ~/scripts/opsman-func.sh
iaas::initialize

opsman::login_client $OPSMAN_HOST $PCFOPS_CLIENT $PCFOPS_SECRET $OPSMAN_PASSPHRASE
