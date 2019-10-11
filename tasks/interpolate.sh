#!/usr/bin/env sh


set -eu

# Pass in the terraform output as a variable, so if the file doesn't exist the interpolate won't fail.
TERRAFORM_OUTPUT=""
if [[ -f "$PWD/terraform-output/metadata" ]]; then
  TERRAFORM_OUTPUT="-d data=file://$(pwd)/terraform-output/metadata?type=application/json"

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

fi

# The product configs do not need terraform to work, so we run them separately.
mkdir -p interpolated-config/$ENV_NAME/download-product-configs
/bin/gomplate --input-dir config/$ENV_NAME/download-product-configs \
  --output-dir interpolated-config/$ENV_NAME/download-product-configs --verbose