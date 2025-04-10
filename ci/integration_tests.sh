#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.jvmargs=-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

export SPEC_OPTS="--order rand --format documentation"
export CI=true

# Option for running in fedramp high mode
FEDRAMP_FLAG="${FEDRAMP_HIGH_MODE/#/-PfedrampHighMode=}"

if [ -n "$BUILD_JAVA_HOME" ]; then
  GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.home=$BUILD_JAVA_HOME"
fi

if [[ $1 = "setup" ]]; then
 echo "Setup only, no tests will be run"
 exit 0

elif [[ $1 == "split" ]]; then
  # Source shared function for splitting integration tests
  source "$(dirname "${BASH_SOURCE[0]}")/partition-files.lib.sh"

  index="${2:?index}"
  count="${3:-2}"
  specs=($(cd qa/integration; partition_files "${index}" "${count}" < <(find specs -name '*_spec.rb') ))

  echo "Running integration tests partition[${index}] of ${count}: ${specs[*]}"
  ./gradlew runIntegrationTests $FEDRAMP_FLAG -PrubyIntegrationSpecs="${specs[*]}" --console=plain

elif [[ !  -z  $@  ]]; then
    echo "Running integration tests 'rspec $@'"
    ./gradlew runIntegrationTests $FEDRAMP_FLAG -PrubyIntegrationSpecs="$@" --console=plain

else
    echo "Running all integration tests"
    ./gradlew runIntegrationTests $FEDRAMP_FLAG --console=plain
fi
