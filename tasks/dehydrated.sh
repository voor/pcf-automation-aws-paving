#!/usr/bin/env sh
set -eux

ls -la ${PWD}/certificates/
ls -la ${PWD}/certificates-version/
mkdir -p ${PWD}/certificates/ssl/

echo "${ENV_NAME}.${DNS_SUFFIX} *.${ENV_NAME}.${DNS_SUFFIX} *.pks.${ENV_NAME}.${DNS_SUFFIX} > private" > ${PWD}/domains.txt

cat ${PWD}/domains.txt

echo "DOMAINS_TXT=${PWD}/domains.txt
CA=${CA}
CURL_OPTS='${CURL_OPTS}'
CHALLENGETYPE=dns-01
HOOK=/home/dehydrated/hook.sh
HOOK_CHAIN=no
CHAINCACHE=${PWD}/certificates/ssl/chains
CERTDIR=${PWD}/certificates/ssl
ACCOUNTDIR=${PWD}/certificates/ssl/accounts" >> ${PWD}/config

cat ${PWD}/config

/home/dehydrated/dehydrated --accept-terms -c -n -f ${PWD}/config

mkdir -p ${PWD}/updated-certificates
tar cvfz ${PWD}/updated-certificates/certificates-$(cat certificates-version/version).tgz -C ${PWD}/certificates/ ssl/
ls -lah ${PWD}/certificates/ ${PWD}/updated-certificates