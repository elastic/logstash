#!/usr/bin/env bash
set -eo pipefail

export GRADLE_OPTS="-Xmx4g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

echo "Checking local JDK version against latest remote from JVM catalog"
./gradlew checkNewJdkVersion