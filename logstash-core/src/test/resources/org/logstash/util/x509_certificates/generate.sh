# warning: do not use the certificates produced by this tool in production. This is for testing purposes only
set -e

cd "$(dirname "$0")"

rm -rf generated
mkdir generated
cd generated

echo "GENERATED CERTIFICATES FOR TESTING ONLY." >> ./README.txt
echo "DO NOT USE THESE CERTIFICATES IN PRODUCTION" >> ./README.txt

# certificate authority
openssl genrsa -out root.key 4096
openssl req -new -x509 -days 1826 -extensions ca -key root.key -out root.crt -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=root" -config ../openssl.cnf
openssl x509 -in root.crt -inform pem -outform der | sha256sum | awk '{print $1}' > root.der.sha256

# intermediate CA
openssl genrsa -out intermediate-ca.key 4096
openssl req -new -key intermediate-ca.key -out intermediate-ca.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=intermediate-ca" -config ../openssl.cnf
openssl x509 -req -days 1000 -extfile ../openssl.cnf -extensions intermediate_ca -in intermediate-ca.csr -CA root.crt -CAkey root.key -out intermediate-ca.crt -set_serial 01
openssl x509 -in intermediate-ca.crt -inform pem -outform der | sha256sum | awk '{print $1}' > intermediate-ca.der.sha256

# server certificate from intermediate CA
openssl genrsa -out server_from_intermediate.key 4096
openssl req -new -key server_from_intermediate.key -out server_from_intermediate.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=server" -config ../openssl.cnf
openssl x509 -req -extensions server_cert -extfile ../openssl.cnf -days 1000 -in server_from_intermediate.csr -CA intermediate-ca.crt -CAkey intermediate-ca.key -set_serial 02 -out server_from_intermediate.crt
openssl x509 -in server_from_intermediate.crt -inform pem -outform der | sha256sum | awk '{print $1}' > server_from_intermediate.der.sha256

# server certificate from root
openssl genrsa -out server_from_root.key 4096
openssl req -new -key server_from_root.key -out server_from_root.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=server" -config ../openssl.cnf
openssl x509 -req -extensions server_cert -extfile ../openssl.cnf -days 1000 -in server_from_root.csr -CA root.crt -CAkey root.key -set_serial 03 -out server_from_root.crt
openssl x509 -in server_from_root.crt -inform pem -outform der | sha256sum | awk '{print $1}'  > server_from_root.der.sha256

# create server chain pems.
cat intermediate-ca.crt server_from_intermediate.crt > server_from_intermediate.chain.crt
cat server_from_root.crt > server_from_root.chain.crt

# verify :allthethings
openssl verify -CAfile root.crt intermediate-ca.crt
openssl verify -CAfile root.crt server_from_root.crt
openssl verify -CAfile root.crt -untrusted intermediate-ca.crt server_from_intermediate.crt
openssl verify -CAfile root.crt server_from_root.chain.crt
openssl verify -CAfile root.crt server_from_intermediate.chain.crt

# output ISO8601 timestamp to file
date -Iseconds > GENERATED_AT

# cleanup csr, we don't need them
rm -rf *.csr
