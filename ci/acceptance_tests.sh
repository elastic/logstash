#!/usr/bin/env bash
set -eo pipefail

function get_package_type {
  # determines OS packaging system; at the moment either rpm or deb
  source /etc/os-release

  if [[ $ID == "ubuntu" || $ID == "debian" || $ID_LIKE == "debian" ]]; then
    PACKAGE_TYPE="deb"
  elif [[ $ID_LIKE == *"rhel"* || $ID_LIKE == *"fedora"* || $ID_LIKE == *"suse"* ]]; then
    PACKAGE_TYPE="rpm"
  else
    echo "^^^ +++ Unsupported Linux distribution [$ID]. Acceptance packaging tests only support deb or rpm based distributions. Exiting."
    exit 1
  fi
}

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx4g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"
export OSS=true

if [ -n "$BUILD_JAVA_HOME" ]; then
  GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.home=$BUILD_JAVA_HOME"
fi

LS_HOME="$PWD"
QA_DIR="$PWD/qa"

cd $LS_HOME

get_package_type

# in CI (Buildkite), packaging artifacts are pre-built from a previous step
if [[ $BUILDKITE == true ]]; then
  export LS_ARTIFACTS_PATH="$HOME/build"
  echo "--- Downloading artifacts from \"build/*${PACKAGE_TYPE}\" to $LS_ARTIFACTS_PATH"
  set -x
  # also creates build/ under $HOME
  buildkite-agent artifact download "build/*${PACKAGE_TYPE}" $HOME
  set +x
  echo "--- Running gradle"
  ./gradlew clean bootstrap
else
  echo "--- Detected a distribution that supports \033[33m[$PACKAGE_TYPE]\033[0m packages. Running gradle."
  ./gradlew clean bootstrap
  echo "--- Building Logstash artifacts"
  rake artifact:$PACKAGE_TYPE
fi

echo "--- Acceptance: Installing dependencies"
cd $QA_DIR
bundle install

echo "--- Acceptance: Running the tests"
rake qa:acceptance:all
