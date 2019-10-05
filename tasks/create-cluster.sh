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

$PKS_CLI cluster ${CLUSTER_NAME}

if [ $? -ne 0 ]; then
    echo "Creating ${CLUSTER_NAME} cluster..."
    $PKS_CLI create-cluster ${CLUSTER_NAME} -n 2 -p ${PLAN_NAME} -e ${CLUSTER_NAME}.pks.${ENV_NAME}.${DNS_NAME}
else
    echo "${CLUSTER_NAME} cluster already exists, checking it's created, retrieving information and making sure subnet tags are there..."
fi

while $PKS_CLI cluster ${CLUSTER_NAME} | grep -m 1 "In Progress"; do sleep 15; done

set -e

mkdir -p master-instances

echo "cluster_name: ${CLUSTER_NAME}" > master-instances/${CLUSTER_NAME}.cluster.yml
echo "cluster_host: ${CLUSTER_NAME}.pks.${ENV_NAME}.${DNS_NAME}" >> master-instances/${CLUSTER_NAME}.cluster.yml

$PKS_CLI cluster ${CLUSTER_NAME} --json >> master-instances/${CLUSTER_NAME}.pks-cluster.json
bosh vms --json
bosh vms --json >> master-instances/${CLUSTER_NAME}.bosh-vms.json

export CLUSTER_UUID=$($PKS_CLI cluster ${CLUSTER_NAME} --json | om interpolate --path /uuid)
aws ec2 create-tags --resources $(cat env/${SUBNETS_FILE}) --tags Key=kubernetes.io/cluster/service-instance_${CLUSTER_UUID},Value=shared

export KUBECONFIG=master-instances/${CLUSTER_NAME}.kubeconfig

$PKS_CLI get-credentials ${CLUSTER_NAME}

echo "Output kubeconfig for cluster ${CLUSTER_NAME} to ${KUBECONFIG}"