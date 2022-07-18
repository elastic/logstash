#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.jvmargs=-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

export SPEC_OPTS="--order rand --format documentation"
export CI=true

if [ -n "$BUILD_JAVA_HOME" ]; then
  GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.home=$BUILD_JAVA_HOME"
fi

if [[ $1 = "setup" ]]; then
 echo "Setup only, no tests will be run"
 exit 0

elif [[ $1 == "split" ]]; then
    cd qa/integration
    glob1=(specs/*spec.rb)
    glob2=(specs/**/*spec.rb)
    all_specs=("${glob1[@]}" "${glob2[@]}")

    specs0=${all_specs[@]::$((${#all_specs[@]} / 2 ))}
    specs1=${all_specs[@]:$((${#all_specs[@]} / 2 ))}
    cd ../..
    if [[ $2 == 0 ]]; then
       echo "Running the first half of integration specs: $specs0"
       ./gradlew runIntegrationTests -PrubyIntegrationSpecs="$specs0" --console=plain
    elif [[ $2 == 1 ]]; then
       echo "Running the second half of integration specs: $specs1"
       ./gradlew runIntegrationTests -PrubyIntegrationSpecs="$specs1" --console=plain
    else
       echo "Error, must specify 0 or 1 after the split. For example ci/integration_tests.sh split 0"
       exit 1
    fi

elif [[ !  -z  $@  ]]; then
    echo "Running integration tests 'rspec $@'"
    ./gradlew runIntegrationTests -PrubyIntegrationSpecs="$@" --console=plain

else
    echo "Running all integration tests"
    ./gradlew runIntegrationTests --console=plain
fi
