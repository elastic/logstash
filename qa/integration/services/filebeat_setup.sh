#!/bin/bash
set -e
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

generate_certificate() {
    target_directory=$current_dir/../fixtures/certificates
    mkdir -p $target_directory
    openssl req -subj '/CN=localhost/' -x509 -days $((100 * 365)) -batch -nodes -newkey rsa:2048 -keyout $target_directory/certificate.key -out $target_directory/certificate.crt
}

generate_certificate
