#!/usr/bin/env bash

cat /var/version && echo ""
set -eu
# shellcheck disable=SC2068
om --env env/"${ENV_FILE}" update-ssl-certificate \
    --certificate-pem "$(cat config/${CERTIFICATE_PEM})" \
    --private-key-pem "$(cat config/${PRIVATE_KEY_PEM})"