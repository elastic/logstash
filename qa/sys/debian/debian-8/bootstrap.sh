#!/usr/bin/env bash

echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
apt-get update
apt-get install -y openjdk-8-jdk
