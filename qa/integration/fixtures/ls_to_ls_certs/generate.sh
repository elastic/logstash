#!/usr/bin/env bash
# warning: do not use the certificates produced by this tool in production.
# This is for testing purposes only
set -e

cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P

rm -rf generated
mkdir generated
cd generated

echo "GENERATED CERTIFICATES FOR TESTING ONLY." >> ./README.txt
echo "DO NOT USE THESE CERTIFICATES IN PRODUCTION" >> ./README.txt

function generate_usable_identity_variants {
	name="${1:?cert name required}"

	openssl pkcs8 -topk8 -inform PEM -outform PEM -passout "pass:12345678" -in "${name}.key.pem" -out "${name}.key.pkcs8.pem"
	openssl pkcs12 -export -in "${name}.pem" -inkey "${name}.key.pem" -out "${name}.p12" -name "${name}" -passout 'pass:12345678'
	keytool -importkeystore -srckeystore "${name}.p12" -srcstoretype pkcs12 -srcstorepass 12345678 -destkeystore "${name}.jks" -deststorepass 12345678 -alias "${name}"
}

function generate_usable_trust_variants {
	echo 'hello'
}

# trustworthy root certificate authority
openssl genrsa -out root.key.pem 4096
openssl req -new -x509 -days 1826 -extensions ca -key root.key.pem -out root.pem -subj "/C=LS/ST=NA/L=Http Input/O=Logstash/CN=root" -config ../openssl.cnf

# server certificate from root
openssl genrsa -out server_from_root.key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in server_from_root.key.pem -out server_from_root-key-pkcs8.pem
openssl req -new -key server_from_root.key.pem -out server_from_root.csr -subj "/C=LS/ST=NA/L=Http Input/O=Logstash/CN=server" -config ../openssl.cnf
openssl x509 -req -extensions server_cert -extfile ../openssl.cnf -days 1096 -in server_from_root.csr -CA root.pem -CAkey root.key.pem -set_serial 03 -out server_from_root.pem -sha256
generate_usable_identity_variants "server_from_root"

# client certificate from root
openssl genrsa -out client_from_root.key.pem 4096
openssl req -new -key client_from_root.key.pem -out client_from_root.csr -subj "/C=LS/ST=NA/L=Http Input/O=Logstash/CN=client" -config ../openssl.cnf
openssl x509 -req -extensions client_cert -extfile ../openssl.cnf -days 1096 -in client_from_root.csr -CA root.pem -CAkey root.key.pem -set_serial 04 -out client_from_root.pem -sha256
generate_usable_identity_variants "client_from_root"

# self-signed for testing
openssl req -newkey rsa:4096 -nodes -keyout client_self_signed.key.pem -x509 -days 365 -out client_self_signed.pem -subj "/C=LS/ST=NA/L=Http Input/O=Logstash/CN=self"
generate_usable_identity_variants "client_self_signed"

# untrusted root certificate authority
openssl genrsa -out untrusted.key.pem 4096
openssl req -new -x509 -days 1826 -extensions ca -key untrusted.key.pem -out untrusted.pem -subj "/C=LS/ST=NA/L=Http Input/O=Logstash/CN=other" -config ../openssl.cnf

# client certificate from untrusted root
openssl genrsa -out client_from_untrusted.key.pem 4096
openssl req -new -key client_from_untrusted.key.pem -out client_from_untrusted.csr -subj "/C=LS/ST=NA/L=Http Input/O=Logstash/CN=client" -config ../openssl.cnf
openssl x509 -req -extensions client_cert -extfile ../openssl.cnf -days 1096 -in client_from_untrusted.csr -CA untrusted.pem -CAkey untrusted.key.pem -set_serial 04 -out client_from_untrusted.pem -sha256
generate_usable_identity_variants "client_from_untrusted"

# verify :allthethings
openssl verify -CAfile root.pem server_from_root.pem
openssl verify -CAfile root.pem client_from_root.pem

! openssl verify -CAfile root.pem client_from_untrusted.pem 2> /dev/null
openssl verify -CAfile untrusted.pem client_from_untrusted.pem

! openssl verify -CAfile root.pem client_self_signed.pem 2> /dev/null
openssl verify -CAfile client_self_signed.pem client_self_signed.pem

# cleanup csr, we don't need them
rm -rf *.csr
