#!/bin/bash
set -e
current_dir="$(dirname "$0")"

INSTALL_DIR=$current_dir/installed
PORT_WAIT_COUNT=20

setup_install_dir() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir $INSTALL_DIR
    fi
}

wait_for_port() {
    count=$PORT_WAIT_COUNT
    while ! test_port "$1"  && [[ $count -ne 0 ]]; do
        count=$(( $count - 1 ))
        [[ $count -eq 0 ]] && return 1
        sleep 0.5
    done
    # just in case, one more time
    test_port "$1"
}

test_port(){
  /bin/bash -c "(echo >/dev/tcp/localhost/$1) >/dev/null 2>&1"
}

clean_install_dir() {
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf $INSTALL_DIR
    fi
}
