#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx4g -Dorg.gradle.jvmargs=-Xmx4g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

export SPEC_OPTS="--order rand --format documentation"
export CI=true
export TEST_DEBUG=true
# don't rely on bash booleans for truth checks, since some CI platforms don't have a way to specify env vars as boolean
export ENABLE_SONARQUBE=${ENABLE_SONARQUBE:-"true"}

if [ -n "$BUILD_JAVA_HOME" ]; then
  GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.home=$BUILD_JAVA_HOME"
fi

if [[ $BUILDKITE == true ]]; then
  # Buildkite annotations for rspec: https://github.com/buildkite/rspec-buildkite
  cat >>Gemfile.template <<@EOF
gem "rspec-buildkite", "~> 0.1", :group => :development
@EOF
  export SPEC_OPTS="--order rand --color --require spec_helper --format documentation --format RSpec::Buildkite::AnnotationFormatter"
fi

SELECTED_TEST_SUITE=$1

if [[ $SELECTED_TEST_SUITE == $"java" ]]; then
  SONAR_ARGS=()

  if [[ $(echo $ENABLE_SONARQUBE | tr '[:lower:]' '[:upper:]') == "TRUE" ]]; then
    SONAR_ARGS=(
      "jacocoTestReport"
      "sonar"
      "-Dsonar.token=${SONAR_TOKEN}"
      "-Dsonar.host.url=https://sonar.elastic.dev"
      "-Dsonar.projectKey=elastic_logstash_AYm_nEbQaV3I-igkX1q9"
      "-Dsonar.projectName=logstash"
      "-Dsonar.pullrequest.key=$PULL_ID"
      "-Dsonar.pullrequest.branch=$SOURCE_BRANCH"
      "-Dsonar.pullrequest.base=$TARGET_BRANCH"
      "-Dsonar.scm.revision=$COMMIT_SHA"
    )
  fi

  echo "Running Java Tests"
  ./gradlew javaTests "${SONAR_ARGS[@]}" --console=plain --warning-mode all
elif [[ $SELECTED_TEST_SUITE == $"ruby" ]]; then
  echo "Running Ruby unit tests"
  ./gradlew rubyTests --console=plain --warning-mode all
else
  echo "Running Java and Ruby unit tests"
  ./gradlew test --console=plain
fi
