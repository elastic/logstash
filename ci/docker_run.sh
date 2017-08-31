#!/bin/bash -e


if [[ -z "$PROJECT" ]]; then 
  PROJECT="ls-integration"
fi

echo "Using docker-compose project '$PROJECT'"

INTEGRATION_SETUP="cd /opt/logstash; rm -rf build && mkdir -p ~/build; ln -s build ~/build"
COMPOSE_RUN_PREFIX="docker-compose -p $PROJECT run app"

case "$1" in
  "integration")
    echo "Rebuilding images just in case"
    docker-compose build
    time $COMPOSE_RUN_PREFIX bash -i -c "$INTEGRATION_SETUP && ci/travis_integration_install.sh && ci/travis_integration_run.sh ${@:2}"
  ;;
  "cli")
    $COMPOSE_RUN_PREFIX bash -i
  ;;
  *)
    echo "Examples command: "
    echo "# Run integration test"
    echo "ci/docker_run integration"
    echo "# Run a specific integration test"
    echo "ci/docker_run.sh integration ./specs/kafka_input_spec.rb"
    echo "# Start a CLI prompt with the ENV setup for integration tests"
    echo "ci/docker_run cli"
  ;;
esac