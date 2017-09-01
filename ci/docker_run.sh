#!/bin/bash -x

IMAGE_NAME=lsinteg

if [[ -z "$PROJECT" ]]; then 
  PROJECT="ls_integ"
fi

echo "Using docker-compose project '$PROJECT'"

INTEGRATION_SETUP="cd /opt/logstash; rm -rf build"
RUN_PREFIX=docker
LOGSTASH_VERSION=$(cat versions.yml  | egrep '^logstash:' | cut -d' ' -f 2)

function startdev {
  # If container exists, start it
  docker ps -a | awk '{print $NF}' | grep lsdev
  if [[ $? -eq 0 ]]; then
    docker start lsdev
  else # Otherwise run it
    #-agentlib:jdwp=transport=dt_socket,server=y,address=8000,suspend=n
    docker run \
      -v "$PWD:/mnt/host:delegated" \
      -e 'LS_JAVA_OPTS=-Xmx1500M -Xms1500M' \
      -e 'INTEGRATION=true' \
      -e "JRUBY_OPTS=-Xcompile.invokedynamic=false" \
      -d \
      --name lsdev \
      $IMAGE_NAME \
      bash -c ' tail -f /dev/null'
  fi
  # Speeds up gem install etc.
  docker exec lsdev rsync /mnt/host/vendor /opt/logstash/vendor
}

function rsyncdev {
  docker exec lsdev rsync --delete --exclude .git --exclude logs --exclude build --exclude .gradle --exclude vendor -r /mnt/host/ /opt/logstash/ 
}

function build {
  docker build -t $IMAGE_NAME .
}


case "$1" in
  "build") 
    docker stop lsdev
    docker rm lsdev
    build
  ;;
  "rsync_dev")
    rsyncdev
  ;;
  "integration")
    echo "Rebuilding images just in case"
    build
    time $RUN_PREFIX run -it --rm $IMAGE_NAME bash -c "$INTEGRATION_SETUP && ci/integration_install.sh && ci/travis_integration_run.sh ${@:2}"
  ;;
  "parallel-integration")
    build
    num_specs=find qa/integration/ -name "*_spec.rb" | wc -l
  ;;
  "cli")
    $RUN_PREFIX run --rm $IMAGE_NAME bash -l
  ;;
  "integration_dev")
    startdev
    rsyncdev
    time $RUN_PREFIX exec -it lsdev bash -c "ln -sf /opt/logstash build/$LOGSTASH_VERSION && bash -i -c \"$INTEGRATION_SETUP && ci/travis_integration_run.sh ${@:2}\""
  ;;
  "stop_dev")
    $RUN_PREFIX stop lsdev
   ;; 
  "cli_dev")
    startdev
    echo "Don't forget to rsync"
    #TODO: This should search for running containers and connect to them, starting a new one only if needed
    time $RUN_PREFIX exec -it lsdev bash -c "$INTEGRATION_SETUP && mkdir -p build && ln -sf /opt/logstash build/logstash-$LOGSTASH_VERSION-SNAPSHOT && bash -l"
  ;;
  "cleanup_dev")
    docker stop lsdev
    docker rm $(docker ps -aq)
    build
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