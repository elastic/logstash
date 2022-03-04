# warning: do not use the certificates produced by this tool in production. This is for testing purposes only
set -e

rm -rf generated
mkdir generated
cd generated

echo "GENERATED CERTIFICATES FOR TESTING ONLY." >> ./README.txt
echo "DO NOT USE THESE CERTIFICATES IN PRODUCTION" >> ./README.txt

# certificate authority
openssl genrsa -out root.key 4096
openssl req -new -x509 -days 1826 -extensions ca -key root.key -out root.crt -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=root" -config ../openssl.cnf


# intermediate CA
openssl genrsa -out intermediate-ca.key 4096
openssl req -new -key intermediate-ca.key -out intermediate-ca.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=intermediate-ca" -config ../openssl.cnf
openssl x509 -req -days 1000 -extfile ../openssl.cnf -extensions intermediate_ca -in intermediate-ca.csr -CA root.crt -CAkey root.key -out intermediate-ca.crt -set_serial 01

# server certificate from intermediate CA
openssl genrsa -out server_from_intermediate.key 4096
openssl req -new -key server_from_intermediate.key -out server_from_intermediate.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=server" -config ../openssl.cnf
openssl x509 -req -extensions server_cert -extfile ../openssl.cnf -days 1000 -in server_from_intermediate.csr -CA intermediate-ca.crt -CAkey intermediate-ca.key -set_serial 02 -out server_from_intermediate.crt

# server certificate from root
openssl genrsa -out server_from_root.key 4096
openssl req -new -key server_from_root.key -out server_from_root.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=server" -config ../openssl.cnf
openssl x509 -req -extensions server_cert -extfile ../openssl.cnf -days 1000 -in server_from_root.csr -CA root.crt -CAkey root.key -set_serial 03 -out server_from_root.crt


# Client certificates - We don't need them now

# client certificate from intermediate CA
# openssl genrsa -out client_from_intermediate.key 4096
# openssl req -new -key client_from_intermediate.key -out client_from_intermediate.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=client" -config ../openssl.cnf
# openssl x509 -req -extensions client_cert -extfile ../openssl.cnf -days 1000 -in client_from_intermediate.csr -CA intermediate-ca.crt -CAkey intermediate-ca.key -set_serial 04 -out client_from_intermediate.crt

# client certificate from root
# openssl genrsa -out client_from_root.key 4096
# openssl req -new -key client_from_root.key -out client_from_root.csr -subj "/C=PT/ST=NA/L=Lisbon/O=MyLab/CN=client" -config ../openssl.cnf
# openssl x509 -req -extensions client_cert -extfile ../openssl.cnf -days 1000 -in client_from_root.csr -CA root.crt -CAkey root.key -set_serial 04 -out client_from_root.crt

# create server chain pems.
cat intermediate-ca.crt server_from_intermediate.crt > server_from_intermediate.chain.crt
cat server_from_root.crt > server_from_root.chain.crt

# verify :allthethings
openssl verify -CAfile root.crt intermediate-ca.crt
openssl verify -CAfile root.crt server_from_root.crt
openssl verify -CAfile root.crt -untrusted intermediate-ca.crt server_from_intermediate.crt
openssl verify -CAfile root.crt server_from_root.chain.crt
openssl verify -CAfile root.crt server_from_intermediate.chain.crt

# create pkcs8 versions of all keys..they may be handy but we don't need them now
# openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in root.key -out root.key.pkcs8
# openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in intermediate-ca.key -out intermediate-ca.key.pkcs8
# openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in server_from_intermediate.key -out server_from_intermediate.key.pkcs8
# openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in server_from_root.key -out server_from_root.key.pkcs8

# create pkcs12 keystores (pass:12345678)
openssl pkcs12 -export -in server_from_intermediate.chain.crt -inkey server_from_intermediate.key -out server_from_intermediate.p12 -name "server_from_intermediate" -passout 'pass:12345678'
openssl pkcs12 -export -in server_from_root.chain.crt -inkey server_from_root.key -out server_from_root.p12 -name "server_from_root" -passout 'pass:12345678'

# use java keytool to convert all pkcs12 keystores to jks-format keystores (pass:12345678)
keytool -importkeystore -srckeystore server_from_intermediate.p12 -srcstoretype pkcs12 -srcstorepass 12345678 -destkeystore server_from_intermediate.jks -deststorepass 12345678 -alias server_from_intermediate
keytool -importkeystore -srckeystore server_from_root.p12 -srcstoretype pkcs12 -srcstorepass 12345678 -destkeystore server_from_root.jks -deststorepass 12345678 -alias server_from_root

# cleanup csr, we don't need them
rm -rf *.csr
