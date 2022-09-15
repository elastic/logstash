#!/bin/bash
# this is a script generates ca, certificate, key for beats <> logstash mutual verification

cd "$(dirname "$0")"

# generate ca
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -out ca.crt -subj "/C=EU/ST=NA/O=Elastic/CN=RootCA"

# generate logstash cert
openssl genrsa -out server.key 2048
openssl req -sha512 -new -key server.key -out server.csr -subj "/C=EU/ST=NA/O=Elastic/CN=ServerHostName"
openssl x509 -days 3650 -req -sha512 -in server.csr -CAcreateserial -CA ca.crt -CAkey ca.key -out server.crt -extensions server_cert -extfile openssl.conf
openssl pkcs8 -in server.key -topk8 -nocrypt -out server.pkcs8.key

# generate beats cert
openssl genrsa -out client.key 2048
openssl req -sha512 -new -key client.key -out client.csr -subj "/C=EU/ST=NA/O=Elastic/CN=ClientName"
openssl x509 -days 3650 -req -sha512 -in client.csr -CAcreateserial -CA ca.crt -CAkey ca.key -out client.crt -extensions client_cert -extfile openssl.conf

# generate secret.yaml
kubectl create secret generic logstash-beats-tls --from-file=ca.crt --from-file=client.crt --from-file=client.key --from-file=server.crt --from-file=server.pkcs8.key --dry-run=client -o yaml | kubectl label -f- --dry-run=client -o yaml --local app=logstash-demo  > ../001-secret.yaml