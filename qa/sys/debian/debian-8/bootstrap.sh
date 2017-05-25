#!/usr/bin/env bash

echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
puts "installing jdk8"
apt-get update
apt-get install -y ca-certificates-java openjdk-8-jdk-headless
