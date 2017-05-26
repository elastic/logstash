#!/bin/bash

##
# Add routines and/or variables that can be shared between the
# service containers.
##

PORT_WAIT_COUNT=20

# Check service responds on given port.
# Parameters:
#   - the port number.
wait_for_port() {
    count=$PORT_WAIT_COUNT
    port=$1
    while ! nc -z localhost $port && [[ $count -ne 0 ]]; do
        count=$(( $count - 1 ))
        [[ $count -eq 0 ]] && return 1
        sleep 0.5
    done
    # just in case, one more time
    nc -z localhost $port
}
