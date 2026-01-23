#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

export JRUBY_OPTS="-J-Xmx1g"
export SERVERLESS=true
setup_vault

./gradlew runServerlessDLQTests
