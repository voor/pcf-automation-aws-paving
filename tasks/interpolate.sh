#!/usr/bin/env bash

set -eu
mkdir -p interpolated-config/$ENV_NAME/config
/bin/gomplate --input-dir config/$ENV_NAME/config \
    -d data=file://$(pwd)/terraform-output/metadata?type=application/json \
    -d fullchain=file://$(pwd)/certificates/ssl/private/fullchain.pem \
    -d privkey=file://$(pwd)/certificates/ssl/private/privkey.pem \
    --output-dir interpolated-config/$ENV_NAME/config --verbose

mkdir -p interpolated-config/$ENV_NAME/env
/bin/gomplate -f config/$ENV_NAME/env/env.yml \
    -d data=file://$(pwd)/terraform-output/metadata?type=application/json \
    -o interpolated-config/$ENV_NAME/env/env.yml --verbose

mkdir -p interpolated-config/$ENV_NAME/download-product-configs
/bin/gomplate --input-dir config/$ENV_NAME/download-product-configs \
    -d data=file://$(pwd)/terraform-output/metadata?type=application/json \
    --output-dir interpolated-config/$ENV_NAME/download-product-configs --verbose