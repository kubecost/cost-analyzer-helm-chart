#!/bin/bash

namespace=$1
if [ "$namespace" == "" ]; then
  namespace=kubecost
fi

DIRECTORY=$(cd `dirname $0` && pwd)

echo "Creating certificates"
mkdir certs
openssl genrsa -out certs/tls.key 2048
openssl req -new -key certs/tls.key -out certs/tls.csr -subj "/CN=webhook-server.$namespace.svc"
openssl x509 -req -days 500 -extfile <(printf "subjectAltName=DNS:webhook-server.$namespace.svc") -in certs/tls.csr -signkey certs/tls.key -out certs/tls.crt

echo "Creating Webhook Server TLS Secret"
kubectl create secret tls webhook-server-tls \
    --cert "certs/tls.crt" \
    --key "certs/tls.key" -n $namespace


echo "Updating values.yaml"
ENCODED_CA=$(cat certs/tls.crt | base64 | tr -d '\n')
sed -i 's@${CA_BUNDLE}@'"$ENCODED_CA"'@g' ../values.yaml
