#!/bin/bash
set -e
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

if [ -n "${FILEBEAT_VERSION}" ]; then
  echo "Filebeat version is $FILEBEAT_VERSION"
  version=$FILEBEAT_VERSION
else
  version=5.0.1
fi

FB_HOME=$INSTALL_DIR/filebeat

setup_fb() {
    local version=$1
    platform=`uname -s | tr '[:upper:]' '[:lower:]'`
    architecture=`uname -m | tr '[:upper:]' '[:lower:]'`
    download_url=https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$version-$platform-$architecture.tar.gz
    curl -sL $download_url > $INSTALL_DIR/filebeat.tar.gz
    mkdir $FB_HOME
    tar -xzf $INSTALL_DIR/filebeat.tar.gz --strip-components=1 -C $FB_HOME/.
    rm $INSTALL_DIR/filebeat.tar.gz
}

generate_certificate() {
    target_directory=$current_dir/../fixtures/certificates
    mkdir -p $target_directory
    openssl req -subj '/CN=localhost/' -x509 -days $((100 * 365)) -batch -nodes -newkey rsa:2048 -keyout $target_directory/certificate.key -out $target_directory/certificate.crt
}

setup_install_dir

if [ ! -d $FB_HOME ]; then
    generate_certificate
    setup_fb $version
fi
