#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

export SPEC_OPTS="--order rand --format documentation"
export CI=true
export OSS=true
export TEST_DEBUG=true

SELECTED_TEST_SUITE=$1

if [[ $SELECTED_TEST_SUITE == $"java" ]]; then
  echo "Running Java Tests"
  ./gradlew javaTests --console=plain
elif [[ $SELECTED_TEST_SUITE == $"ruby" ]]; then
  echo "Running Ruby unit tests"
  ./gradlew rubyTests --console=plain
else
  echo "Running Java and Ruby unit tests"
  ./gradlew test --console=plain
fi
