#!/bin/bash

echo "Generating CA certificate"
openssl req -x509 -newkey rsa:3072 -days 365 -nodes -keyout ca.key -out ca.crt -subj "/CN=Elastic-CA" -sha256

echo "Generating Elasticsearch certificate"
openssl req -newkey rsa:3072 -nodes -keyout elasticsearch.key -out elasticsearch.csr -subj "/CN=elasticsearch" -sha256
openssl x509 -req -in elasticsearch.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out elasticsearch.crt -days 365 -sha256

echo "Generating Logstash certificate"
openssl req -newkey rsa:3072 -nodes -keyout logstash.key -out logstash.csr -subj "/CN=logstash" -sha256
openssl x509 -req -in logstash.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out logstash.crt -days 365 -sha256

echo "Generating Filebeat certificate"
openssl req -newkey rsa:3072 -nodes -keyout filebeat.key -out filebeat.csr -subj "/CN=filebeat" -sha256
openssl x509 -req -in filebeat.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out filebeat.crt -days 365 -sha256

chmod 644 *.crt *.key
