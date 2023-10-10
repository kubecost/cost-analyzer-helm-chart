#!/bin/bash

namespace=$1
if [[ "${namespace}" == "" ]]; then
  namespace=kubecost
fi

echo -e "\nCreating certificates ..."
mkdir certs
openssl genrsa -out certs/tls.key 2048
openssl req -new -key certs/tls.key -out certs/tls.csr -subj "/CN=webhook-server.${namespace}.svc"
openssl x509 -req -days 500 -extfile <(printf "subjectAltName=DNS:webhook-server.%s.svc" "${namespace}") -in certs/tls.csr -signkey certs/tls.key -out certs/tls.crt

echo -e "\nCreating Webhook Server TLS Secret ..."
kubectl create secret tls webhook-server-tls \
    --cert "certs/tls.crt" \
    --key "certs/tls.key" -n "${namespace}"

echo -e "\nUpdating values.yaml ..."
ENCODED_CA=$(base64 < certs/tls.crt | tr -d '\n')
sed -i '' 's@${CA_BUNDLE}@'"${ENCODED_CA}"'@g' ../values.yaml
