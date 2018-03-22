#!/bin/bash
# Syntax is docker_run.sh IMAGE_NAME SCRIPT_NAME *EXTRA_DOCKER_OPTS

set -x # We want verbosity here, this mostly runs on CI and we want to easily debug stuff

#Note - ensure that the -e flag is NOT set, and explicitly check the $? status to allow for clean up

REMOVE_IMAGE=false
if [ -z "$branch_specifier" ]; then
    # manual
    REMOVE_IMAGE=true
    IMAGE_NAME="$1"
else
    IMAGE_NAME=$branch_specifier"-"$(date +%s%N)
fi

echo "Running Docker CI build for '$IMAGE_NAME' "

# Remove old docker cid just in case
rm -f docker_cid

docker build -t $IMAGE_NAME .
exit_code=$?; [[ $exit_code != 0 ]] && exit $exit_code

cleanup() {
  cat docker_cid | xargs docker rm --force -v 
}
trap cleanup EXIT

# Run the command, skip the first argument, which is the image name
echo "Running tests in built docker image"
docker run --sig-proxy=true --cidfile=docker_cid --rm $IMAGE_NAME ${@:2}
exit_code=$?
[[ $REMOVE_IMAGE == "true" ]] && docker rmi $IMAGE_NAME
echo "exiting with code: '$exit_code'"
exit $exit_code #preserve the exit code from the test run