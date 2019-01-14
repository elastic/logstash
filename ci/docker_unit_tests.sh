#!/bin/bash
#Note - ensure that the -e flag is NOT set, and explicitly check the $? status to allow for clean up

if [ -z "$branch_specifier" ]; then
    # manual
    IMAGE_NAME="logstash-unit-tests"
else
    # Jenkins
    IMAGE_NAME=$branch_specifier"-"$(date +%s%N)
fi

echo "Running Docker CI build for '$IMAGE_NAME' "

docker build  -t $IMAGE_NAME .
exit_code=$?; [[ $exit_code != 0 ]] && exit $exit_code
docker run --sig-proxy=true --rm $IMAGE_NAME ci/unit_tests.sh $@
exit_code=$?
[[ $IMAGE_NAME != "logstash-unit-tests" ]] && docker rmi $IMAGE_NAME
echo "exiting with code: '$exit_code'"
exit $exit_code #preserve the exit code from the test run
