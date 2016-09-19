#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

if [ -n "${FILEBEAT_VERSION}" ]; then
  echo "Filebeat version is $FILEBEAT_VERSION"
  version=$FILEBEAT_VERSION
else
   version=5.0.0-alpha6
fi

setup_fb() {
    local version=$1
    platform=`uname -s | tr '[:upper:]' '[:lower:]'`
    architecture=`uname -m | tr '[:upper:]' '[:lower:]'`
    download_url=https://download.elastic.co/beats/filebeat/filebeat-$version-$platform-$architecture.tar.gz
    curl -sL $download_url > $current_dir/filebeat.tar.gz
    mkdir $current_dir/filebeat
    tar -xzf $current_dir/filebeat.tar.gz --strip-components=1 -C $current_dir/filebeat/.
    rm $current_dir/filebeat.tar.gz
}

generate_certificate() {
    target_directory=$current_dir/../fixtures/certificates
    mkdir -p $target_directory
    openssl req -subj '/CN=localhost/' -x509 -days $((100 * 365)) -batch -nodes -newkey rsa:2048 -keyout $target_directory/certificate.key -out $target_directory/certificate.crt
}

if [ ! -d $current_dir/filebeat ]; then
    generate_certificate
    setup_fb $version
fi
