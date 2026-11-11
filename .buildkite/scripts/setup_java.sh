#!/bin/bash

set -e

install_java() {
  # TODO: let's think about regularly creating a custom image for Logstash which may align on version.yml definitions
  sudo apt update && sudo apt install -y openjdk-21-jdk && sudo apt install -y openjdk-21-jre
}

install_java
