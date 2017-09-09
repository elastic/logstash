#!/bin/bash -ie

if [ -z "$branch_specifier" ]; then
    # manual
    IMAGE_NAME="logstash-unit-tests"
else
    # Jenkins
    IMAGE_NAME=$branch_specifier"-"$(date +%s%N)
fi

echo "Running CI build for '$IMAGE_NAME' "

docker build  -t $IMAGE_NAME .
docker run -t --rm $IMAGE_NAME ci/unit_tests.sh
[[ $IMAGE_NAME = "logstash-unit-tests" ]] && docker rmi $IMAGE_NAME

