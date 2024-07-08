#!/usr/bin/env bash
set -eo pipefail

# *******************************************************
# This script does benchmark by running Filebeats (docker) -> Logstash (docker) -> ES Cloud.
# Logstash metrics and benchmark results are sent to the same ES Cloud.
# Highlights:
# - Use flog (docker) to generate ~2GB log
# - Pull the snapshot docker image of the main branch every day
# - Logstash runs two pipelines, main and node_stats
#   - The main pipeline handles beats ingestion, sending data to the data stream `logs-generic-default`
#     - It runs for all combinations. (pq + mq) x worker x batch size
#     - Each test runs for ~7 minutes
#   - The node_stats pipeline retrieves Logstash /_node/stats every 30s and sends it to the data stream `metrics-nodestats-logstash`
# - The script sends a summary of EPS and resource usage to index `benchmark_summary`
# *******************************************************

SCRIPT_PATH="$(cd "$(dirname "$0")"; pwd)"
CONFIG_PATH="$SCRIPT_PATH/config"
source "$SCRIPT_PATH/util.sh"

## usage:
##   main.sh FB_CNT QTYPE CPU MEM
##   main.sh 4 all 4 4          # default launch 4 filebeats to benchmark pq and mq
##   main.sh 4 memory
##   main.sh 4 persisted
##   main.sh 4
##   main.sh
## accept env vars:
##   FB_VERSION=8.13.4          # docker tag
##   LS_VERSION=8.15.0-SNAPSHOT # docker tag
##   LS_JAVA_OPTS=-Xmx2g        # by default, Xmx is set to half of memory
##   MULTIPLIERS=1,2,4          # determine the number of workers (cpu * multiplier)
##   BATCH_SIZES=125,500
##   CPU=4                      # number of cpu for Logstash container
##   MEM=4                      # number of GB for Logstash container
##   QTYPE=memory               # queue type to test {persisted|memory|all}
##   FB_CNT=4                   # number of filebeats to use in benchmark
usage() {
  echo "Usage: $0 [FB_CNT] [QTYPE] [CPU] [MEM]"
  echo "Example: $0 4 {persisted|memory|all} 2 2"
  exit 1
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    if [ -z "$FB_CNT" ]; then
      FB_CNT=$1
    elif [ -z "$QTYPE" ]; then
      case $1 in
        all | persisted | memory)
            QTYPE=$1
            ;;
        *)
          echo "Error: wrong queue type $1"
          usage
          ;;
      esac
    elif [ -z "$CPU" ]; then
      CPU=$1
    elif [ -z "$MEM" ]; then
      MEM=$1
    else
      echo "Error: Too many arguments"
      usage
    fi
    shift
  done

  # set default value
  # number of filebeat
  FB_CNT=${FB_CNT:-4}
  # all | persisted | memory
  QTYPE=${QTYPE:-all}
  CPU=${CPU:-4}
  MEM=${MEM:-4}
  XMX=$((MEM / 2))

  IFS=','
  # worker multiplier: 1,2,4
  MULTIPLIERS="${MULTIPLIERS:-1,2,4}"
  read -ra MULTIPLIERS <<< "$MULTIPLIERS"
  BATCH_SIZES="${BATCH_SIZES:-500}"
  read -ra BATCH_SIZES <<< "$BATCH_SIZES"

  IFS=' '
  echo "filebeats: $FB_CNT, cpu: $CPU, mem: $MEM, Queue: $QTYPE, worker multiplier: ${MULTIPLIERS[@]}, batch size: ${BATCH_SIZES[@]}"
}

get_secret() {
  VAULT_PATH=secret/ci/elastic-logstash/benchmark
  VAULT_DATA=$(vault kv get -format json $VAULT_PATH)
  BENCHMARK_ES_HOST=$(echo $VAULT_DATA | jq -r '.data.es_host')
  BENCHMARK_ES_USER=$(echo $VAULT_DATA | jq -r '.data.es_user')
  BENCHMARK_ES_PW=$(echo $VAULT_DATA | jq -r '.data.es_pw')

  MONITOR_ES_HOST=$(echo $VAULT_DATA | jq -r '.data.monitor_es_host')
  MONITOR_ES_USER=$(echo $VAULT_DATA | jq -r '.data.monitor_es_user')
  MONITOR_ES_PW=$(echo $VAULT_DATA | jq -r '.data.monitor_es_pw')
}

pull_images() {
  echo "--- Pull docker images"

  # pull the latest snapshot logstash image
  if [[ -n "$LS_VERSION" ]]; then
    docker pull "docker.elastic.co/logstash/logstash:$LS_VERSION"
  else
    # select the SNAPSHOT artifact with the highest semantic version number
    LS_VERSION=$( curl --retry-all-errors --retry 5 --retry-delay 1 -s https://artifacts-api.elastic.co/v1/versions | jq -r '.versions | map(select(endswith("-SNAPSHOT"))) | max_by(rtrimstr("-SNAPSHOT")|split(".")|map(tonumber))' )
    BUILD_ID=$(curl --retry-all-errors --retry 5 --retry-delay 1 -s "https://artifacts-api.elastic.co/v1/versions/${LS_VERSION}/builds/latest" | jq -re '.build.build_id')
    ARCH=$(arch)
    IMAGE_URL="https://snapshots.elastic.co/${BUILD_ID}/downloads/logstash/logstash-$LS_VERSION-docker-image-$ARCH.tar.gz"
    IMAGE_FILENAME="$LS_VERSION.tar.gz"

    echo "Download $LS_VERSION from $IMAGE_URL"
    [[ ! -e $IMAGE_FILENAME ]] && curl -fsSL --retry-max-time 60 --retry 3 --retry-delay 5 -o "$IMAGE_FILENAME" "$IMAGE_URL"
    [[ -z $(docker images -q docker.elastic.co/logstash/logstash:$LS_VERSION) ]] && docker load -i "$IMAGE_FILENAME"
  fi

  # pull filebeat image
  FB_DEFAULT_VERSION="8.13.4"
  FB_VERSION=${FB_VERSION:-$FB_DEFAULT_VERSION}
  docker pull "docker.elastic.co/beats/filebeat:$FB_VERSION"
}

generate_logs() {
  FLOG_PATH="$SCRIPT_PATH/flog"
  mkdir -p $FLOG_PATH

  if [[ ! -e "$FLOG_PATH/log4.log" ]]; then
    echo "--- Generate logs in background. log: 5, size: 500mb"
    docker run -d --name=flog --rm -v $FLOG_PATH:/go/src/data mingrammer/flog -t log -w -o "/go/src/data/log.log" -b 2621440000 -p 524288000
  fi
}

check_logs() {
  echo "--- Check log generation"

  local cnt=0
  until [[ -e "$FLOG_PATH/log4.log" || $cnt -gt 600 ]]; do
    echo "wait 30s" && sleep 30
    cnt=$((cnt + 30))
  done

  ls -lah $FLOG_PATH
}

start_logstash() {
  LS_CONFIG_PATH=$SCRIPT_PATH/ls/config
  mkdir -p $LS_CONFIG_PATH

  cp $CONFIG_PATH/pipelines.yml $LS_CONFIG_PATH/pipelines.yml
  cp $CONFIG_PATH/logstash.yml $LS_CONFIG_PATH/logstash.yml

  LS_JAVA_OPTS=${LS_JAVA_OPTS:--Xmx${XMX}g}
  docker run -d --name=ls --net=host --cpus=$CPU --memory=${MEM}g -e LS_JAVA_OPTS="$LS_JAVA_OPTS" \
    -e QTYPE="$QTYPE" -e WORKER="$WORKER" -e BATCH_SIZE="$BATCH_SIZE" \
    -e BENCHMARK_ES_HOST="$BENCHMARK_ES_HOST" -e BENCHMARK_ES_USER="$BENCHMARK_ES_USER" -e BENCHMARK_ES_PW="$BENCHMARK_ES_PW" \
    -e MONITOR_ES_HOST="$MONITOR_ES_HOST" -e MONITOR_ES_USER="$MONITOR_ES_USER" -e MONITOR_ES_PW="$MONITOR_ES_PW" \
    -v $LS_CONFIG_PATH/logstash.yml:/usr/share/logstash/config/logstash.yml:ro \
    -v $LS_CONFIG_PATH/pipelines.yml:/usr/share/logstash/config/pipelines.yml:ro \
    docker.elastic.co/logstash/logstash:$LS_VERSION
}

start_filebeat() {
  for ((i = 0; i < FB_CNT; i++)); do
    FB_PATH="$SCRIPT_PATH/fb${i}"
    mkdir -p $FB_PATH

    cp $CONFIG_PATH/filebeat.yml $FB_PATH/filebeat.yml

    docker run -d --name=fb$i --net=host --user=root \
        -v $FB_PATH/filebeat.yml:/usr/share/filebeat/filebeat.yml \
        -v $SCRIPT_PATH/flog:/usr/share/filebeat/flog \
        docker.elastic.co/beats/filebeat:$FB_VERSION filebeat -e --strict.perms=false
  done
}

capture_stats() {
  CURRENT=$(jq -r '.flow.output_throughput.current' $NS_JSON)
  local eps_1m=$(jq -r '.flow.output_throughput.last_1_minute' $NS_JSON)
  local eps_5m=$(jq -r '.flow.output_throughput.last_5_minutes' $NS_JSON)
  local worker_util=$(jq -r '.pipelines.main.flow.worker_utilization.last_1_minute' $NS_JSON)
  local worker_concurr=$(jq -r '.pipelines.main.flow.worker_concurrency.last_1_minute' $NS_JSON)
  local cpu_percent=$(jq -r '.process.cpu.percent' $NS_JSON)
  local heap=$(jq -r '.jvm.mem.heap_used_in_bytes' $NS_JSON)
  local non_heap=$(jq -r '.jvm.mem.non_heap_used_in_bytes' $NS_JSON)
  local q_event_cnt=$(jq -r '.pipelines.main.queue.events_count' $NS_JSON)
  local q_size=$(jq -r '.pipelines.main.queue.queue_size_in_bytes' $NS_JSON)
  TOTAL_EVENTS_OUT=$(jq -r '.pipelines.main.events.out' $NS_JSON)
  printf "current: %s, 1m: %s, 5m: %s, worker_utilization: %s, worker_concurrency: %s, cpu: %s, heap: %s, non-heap: %s, q_events: %s, q_size: %s, total_events_out: %s\n" \
    $CURRENT $eps_1m $eps_5m $worker_util $worker_concurr $cpu_percent $heap $non_heap $q_event_cnt $q_size $TOTAL_EVENTS_OUT
}

aggregate_stats() {
  local file_glob="$SCRIPT_PATH/$NS_DIR/${QTYPE:0:1}_w${WORKER}b${BATCH_SIZE}_*.json"
  MAX_EPS_1M=$( jqmax '.flow.output_throughput.last_1_minute' "$file_glob" )
  MAX_EPS_5M=$( jqmax '.flow.output_throughput.last_5_minutes' "$file_glob" )
  MAX_WORKER_UTIL=$( jqmax '.pipelines.main.flow.worker_utilization.last_1_minute' "$file_glob" )
  MAX_WORKER_CONCURR=$( jqmax '.pipelines.main.flow.worker_concurrency.last_1_minute' "$file_glob" )
  MAX_Q_EVENT_CNT=$( jqmax '.pipelines.main.queue.events_count' "$file_glob" )
  MAX_Q_SIZE=$( jqmax '.pipelines.main.queue.queue_size_in_bytes' "$file_glob" )

  AVG_CPU_PERCENT=$( jqavg '.process.cpu.percent' "$file_glob" )
  AVG_VIRTUAL_MEM=$( jqavg '.process.mem.total_virtual_in_bytes' "$file_glob" )
  AVG_HEAP=$( jqavg '.jvm.mem.heap_used_in_bytes' "$file_glob" )
  AVG_NON_HEAP=$( jqavg '.jvm.mem.non_heap_used_in_bytes' "$file_glob" )
}

send_summary() {
  echo "--- Send summary to Elasticsearch"

  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
  tee summary.json << EOF
{"index": {}}
{"timestamp": "$timestamp", "version": "$LS_VERSION", "cpu": "$CPU", "mem": "$MEM", "workers": "$WORKER", "batch_size": "$BATCH_SIZE", "queue_type": "$QTYPE", "total_events_out": "$TOTAL_EVENTS_OUT", "max_eps_1m": "$MAX_EPS_1M", "max_eps_5m": "$MAX_EPS_5M", "max_worker_utilization": "$MAX_WORKER_UTIL", "max_worker_concurrency": "$MAX_WORKER_CONCURR", "avg_cpu_percentage": "$AVG_CPU_PERCENT", "avg_heap": "$AVG_HEAP", "avg_non_heap": "$AVG_NON_HEAP", "avg_virtual_memory": "$AVG_VIRTUAL_MEM", "max_queue_events": "$MAX_Q_EVENT_CNT", "max_queue_bytes_size": "$MAX_Q_SIZE"}
EOF
  curl -X POST -u "$BENCHMARK_ES_USER:$BENCHMARK_ES_PW" "$BENCHMARK_ES_HOST/benchmark_summary/_bulk" -H 'Content-Type: application/json' --data-binary @"summary.json"
  echo ""
}

# $1: snapshot index
node_stats() {
  NS_JSON="$SCRIPT_PATH/$NS_DIR/${QTYPE:0:1}_w${WORKER}b${BATCH_SIZE}_$1.json" # m_w8b1000_0.json

  # curl inside container because docker on mac cannot resolve localhost to host network interface
  docker exec -it ls curl localhost:9600/_node/stats > "$NS_JSON" 2> /dev/null
}

# $1: index
snapshot() {
  node_stats $1
  capture_stats
}

create_directory() {
  NS_DIR="fb${FB_CNT}c${CPU}m${MEM}" # fb4c4m4
  mkdir -p "$SCRIPT_PATH/$NS_DIR"
}

queue() {
  for QTYPE in "persisted" "memory"; do
    worker
  done
}

worker() {
  for m in "${MULTIPLIERS[@]}"; do
    WORKER=$((CPU * m))
    batch
  done
}

batch() {
  for BATCH_SIZE in "${BATCH_SIZES[@]}"; do
    run_pipeline
    stop_pipeline
  done
}

run_pipeline() {
  echo "--- Run pipeline. queue type: $QTYPE, worker: $WORKER, batch size: $BATCH_SIZE"

  start_logstash
  start_filebeat
  docker ps

  echo "(0) sleep 3m" && sleep 180
  snapshot "0"

  for i in {1..8}; do
    echo "($i) sleep 30s" && sleep 30
    snapshot "$i"

    # print docker log when ingestion rate is zero
    # remove '.' in number and return max val
    [[ $(max -g "${CURRENT/./}" "0") -eq 0 ]] &&
      docker logs fb0 &&
      docker logs ls
  done

  aggregate_stats
  send_summary
}

stop_pipeline() {
  echo "--- Stop Pipeline"

  for ((i = 0; i < FB_CNT; i++)); do
    docker stop fb$i
    docker rm fb$i
  done

  docker stop ls
  docker rm ls

  curl -u "$BENCHMARK_ES_USER:$BENCHMARK_ES_PW" -X DELETE $BENCHMARK_ES_HOST/_data_stream/logs-generic-default
  echo " data stream deleted "

  # TODO: clean page caches, reduce memory fragmentation
  # https://github.com/elastic/logstash/pull/16191#discussion_r1647050216
}

main() {
  parse_args "$@"
  get_secret

  generate_logs
  pull_images
  check_logs

  create_directory
  if [[ $QTYPE == "all" ]]; then
    queue
  else
    worker
  fi

  # stop log generation if it has not done yet
  [[ -n $(docker ps | grep flog) ]] && docker stop flog || true
}

main "$@"
