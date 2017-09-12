#!/bin/bash -ie

if docker rmi --force logstash-base ; then
    echo "Removed existing logstash-base image, building logstash-base image from scratch."
else
    echo "Building logstash-base image from scratch." #Keep the global -e flag but allow the remove command to fail.
fi

docker build -f Dockerfile.base -t logstash-base .
docker login --username=logstashci container-registry-test.elastic.co #will prompt for password
docker tag logstash-base container-registry-test.elastic.co/logstash-test/logstash-base
docker push container-registry-test.elastic.co/logstash-test/logstash-base
