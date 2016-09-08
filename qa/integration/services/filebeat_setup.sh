#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

if [ -n "${FILEBEAT_VERSION}" ]; then
  echo "Filebeat version is $FILEBEAT_VERSION"
  version=$FILEBEAT_VERSION
else
   version=5.0.0-alpha5
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

if [ ! -d $current_dir/filebeat ]; then
    setup_fb $version
fi
