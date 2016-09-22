#!/usr/bin/env bash
set -e

# This file sets up the environment for travis integration tests


if [[ "$INTEGRATION" != "true" ]]; then
    exit
fi
  
echo "Setting up integration tests"
if [[ ! -d "build" ]]; then
    mkdir build
fi  
rm -rf build/*  
echo "Building logstash tar file in build/"
rake artifact:tar
cd build
echo "Extracting logstash tar file in build/"
tar xf *.tar.gz
cd ../qa/integration
pwd
echo $BUNDLE_GEMFILE
# to install test dependencies
bundle install --gemfile="Gemfile"