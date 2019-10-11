#!/usr/bin/env sh


# Pass in the terraform output as a variable, so if the file doesn't exist the interpolate won't fail.
TERRAFORM_OUTPUT=""
if [[ -f "$PWD/terraform-output/metadata" ]]; then
    TERRAFORM_OUTPUT="-d data=file://$(pwd)/terraform-output/metadata?type=application/json"
fi

set -eu
mkdir -p interpolated-config/$ENV_NAME/config
/bin/gomplate --input-dir config/$ENV_NAME/config \
    $TERRAFORM_OUTPUT \
    -d fullchain=file://$(pwd)/certificates/ssl/private/fullchain.pem \
    -d privkey=file://$(pwd)/certificates/ssl/private/privkey.pem \
    --output-dir interpolated-config/$ENV_NAME/config --verbose

mkdir -p interpolated-config/$ENV_NAME/env
/bin/gomplate -f config/$ENV_NAME/env/env.yml \
    $TERRAFORM_OUTPUT \
    -o interpolated-config/$ENV_NAME/env/env.yml --verbose

mkdir -p interpolated-config/$ENV_NAME/download-product-configs
/bin/gomplate --input-dir config/$ENV_NAME/download-product-configs \
    $TERRAFORM_OUTPUT \
    --output-dir interpolated-config/$ENV_NAME/download-product-configs --verbose