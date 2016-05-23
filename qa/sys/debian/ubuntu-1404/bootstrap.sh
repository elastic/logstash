#!/usr/bin/env bash

add-apt-repository ppa:openjdk-r/ppa
apt-get update
apt-get install -y openjdk-8-jdk
update-alternatives --config java
update-alternatives --config javac
update-ca-certificates -f
