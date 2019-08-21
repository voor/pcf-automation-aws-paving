#!/usr/bin/env sh

set -e
chmod 600 env/"${OPS_MANAGER_KEY_PATH}"
eval "$(om --env env/"${ENV_FILE}" bosh-env --ssh-private-key env/"${OPS_MANAGER_KEY_PATH}")"

export PKS_PASSWORD=$(om --env env/"${ENV_FILE}" credentials --product-name pivotal-container-service -c .properties.uaa_admin_password -f secret)
export PKS_USERNAME="admin"
export PKS_ENDPOINT="https://api.pks.${ENV_NAME}.${DNS_NAME}"
export PKS_CLI=$(ls -1 pks-cli/pks-linux-amd64-*)

chmod +x $PKS_CLI
$PKS_CLI login -a ${PKS_ENDPOINT} -u ${PKS_USERNAME} -p ${PKS_PASSWORD} --ca-cert /etc/ssl/certs/ca-certificates.crt

set -ux
set +e

$PKS_CLI cluster system

if [ $? -ne 0 ]; then
    echo "Creating System cluster..."
    $PKS_CLI create-cluster system -n 2 -p small -e system.pks.${ENV_NAME}.${DNS_NAME}
else
    echo "System cluster already exists, no further action."
fi
set -e

mkdir -p master-instances

echo "cluster_name: system" >> master-instances/cluster.yml
echo "cluster_host: system.pks.${ENV_NAME}.${DNS_NAME}" >> master-instances/cluster.yml

$PKS_CLI cluster system --json >> master-instances/pks-cluster.json
bosh vms --json >> master-instances/bosh-vms.json

export CLUSTER_UUID=$($PKS_CLI cluster system --json | om interpolate --path /uuid)
while read subnet; do
    aws ec2 create-tags --resources ${subnet} --tags Key=kubernetes.io/cluster/service-instance_${CLUSTER_UUID},Value=shared
done <env/${SUBNETS_FILE}