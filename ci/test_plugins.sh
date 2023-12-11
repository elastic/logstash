#!/usr/bin/env bash
set -euo pipefail

export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx4g -Dorg.gradle.jvmargs=-Xmx4g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

./gradlew assemble

vendor/jruby/bin/jruby ci/test_plugins.rb $@
