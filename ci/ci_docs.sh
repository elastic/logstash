#!/usr/bin/env bash
set -e

export JRUBY_OPTS="-J-Xmx2g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false"

# installCore is needed to workaround `group => :development`
# generatePluginsVersion depends on bootstrap and installDefaultGems
echo "Generate json with plugins version"
./gradlew installCore generatePluginsVersion