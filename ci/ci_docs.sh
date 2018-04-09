#!/usr/bin/env bash
set -e

export JRUBY_OPTS="-J-Xmx2g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false"

rake bootstrap
# needed to workaround `group => :development`
rake test:install-core
rake plugin:install-default
echo "Generate json with plugins version"
# Since we generate the lock file and we try to resolve dependencies we will need
# to use the bundle wrapper to correctly find the rake cli. If we don't do this we
# will get an activation error,
./bin/bundle exec rake generate_plugins_version
