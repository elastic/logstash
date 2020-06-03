#!/bin/bash
set -e
current_dir="$(dirname "$0")"

BIN_DIR=$current_dir/../../../bin
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

test_port() {
#    if command -v nc 2>/dev/null; then
#      test_port_nc "$1"
#    else
      test_port_ruby "$1"
#    fi
}

test_port_nc() {
  nc -z localhost $1
}

test_port_ruby() {
  $BIN_DIR/ruby -rsocket -e "TCPSocket.new('localhost', $1) rescue exit(1)"
}

clean_install_dir() {
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf $INSTALL_DIR
    fi
}
