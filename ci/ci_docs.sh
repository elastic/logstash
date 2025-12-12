#!/usr/bin/env bash
set -e

export JRUBY_OPTS="-J-Xmx2g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false"

./gradlew bootstrap
# needed to workaround `group => :development`
./gradlew installCore
./gradlew installDefaultGems
echo "Generate json with plugins version"
./gradlew generatePluginsVersion
