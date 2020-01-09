#!/bin/bash
# 
# Prep
#if [ ! -f oc ]; then
#	curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.2.9.tar.gz
#	tar xzvf openshift-client-linux-4.2.9.tar.gz
#fi
# 
#if [ ! -f openshift-install ]; then
#	curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux-4.2.9.tar.gz
#	tar xzvf openshift-install-linux-4.2.9.tar.gz
#fi

# function from release ci template
function update_image_registry() {
    while true; do
        sleep 10;
        ./oc get configs.imageregistry.operator.openshift.io/cluster > /dev/null && break
    done
    ./oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'
}

set -xe

export KUBECONFIG=${PWD}/auth/kubeconfig
TERRAFORM=${PWD}
IGNITION=${PWD}
TFVARS="${PWD}/terraform.tfvars"

set -x
rm -Rf auth *.ign metadata.json .openshift_install*
(cd ${TERRAFORM} && rm -Rf *.ign .terraform terraform.tfstate terraform.tfstate.backup)
(cd ${IGNITION} && rm -Rf *.ign)

cp install-config{-backup,}.yaml

./openshift-install create ignition-configs
cp -rf  *.ign ignition/
(cd ${TERRAFORM} && terraform init)
(cd ${TERRAFORM} && terraform apply -auto-approve)

./openshift-install wait-for bootstrap-complete --log-level debug

terraform apply -auto-approve -var 'bootstrap_complete=true'

update_image_registry

./openshift-install wait-for install-complete --log-level debug
