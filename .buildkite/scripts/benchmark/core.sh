#!/usr/bin/env bash
set -eo pipefail

SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")"
CONFIG_PATH="$SCRIPT_PATH/config"
source "$SCRIPT_PATH/util.sh"

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
  # tags to json array
  read -ra TAG_ARRAY <<< "$TAGS"
  JSON_TAGS=$(printf '"%s",' "${TAG_ARRAY[@]}" | sed 's/,$//')
  JSON_TAGS="[$JSON_TAGS]"

  IFS=' '
  echo "filebeats: $FB_CNT, cpu: $CPU, mem: $MEM, Queue: $QTYPE, worker multiplier: ${MULTIPLIERS[@]}, batch size: ${BATCH_SIZES[@]}"
}

get_secret() {
  VAULT_PATH=${VAULT_PATH:-secret/ci/elastic-logstash/benchmark}
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

  if [[ -n "$LS_VERSION" ]]; then
    # pull image if it doesn't exist in local
    [[ -z $(docker images -q docker.elastic.co/logstash/logstash:$LS_VERSION) ]] && docker pull "docker.elastic.co/logstash/logstash:$LS_VERSION"
  else
    # pull the latest snapshot logstash image
    # select the SNAPSHOT artifact with the highest semantic version number
    LS_VERSION=$( curl --retry-all-errors --retry 5 --retry-delay 1 -s "https://storage.googleapis.com/artifacts-api/snapshots/main.json" | jq -r '.version' )
    BUILD_ID=$(curl --retry-all-errors --retry 5 --retry-delay 1 -s "https://storage.googleapis.com/artifacts-api/snapshots/main.json" | jq -r '.build_id')
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
  FLOG_FILE_CNT=${FLOG_FILE_CNT:-4}
  SINGLE_SIZE=524288000
  TOTAL_SIZE="$((FLOG_FILE_CNT * SINGLE_SIZE))"
  FLOG_PATH="$SCRIPT_PATH/flog"
  mkdir -p $FLOG_PATH

  if [[ ! -e "$FLOG_PATH/log${FLOG_FILE_CNT}.log" ]]; then
    echo "--- Generate logs in background. log: ${FLOG_FILE_CNT}, each size: 500mb"
    docker run -d --name=flog --rm -v $FLOG_PATH:/go/src/data mingrammer/flog -t log -w -o "/go/src/data/log.log" -b $TOTAL_SIZE -p $SINGLE_SIZE
  fi
}

check_logs() {
  echo "--- Check log generation"

  local cnt=0
  until [[ -e "$FLOG_PATH/log${FLOG_FILE_CNT}.log" || $cnt -gt 600 ]]; do
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
  cp $CONFIG_PATH/uuid $LS_CONFIG_PATH/uuid

  remove_v9_config

  LS_JAVA_OPTS=${LS_JAVA_OPTS:--Xmx${XMX}g}
  docker run -d --name=ls --net=host --cpus=$CPU --memory=${MEM}g -e LS_JAVA_OPTS="$LS_JAVA_OPTS" \
    -e QTYPE="$QTYPE" -e WORKER="$WORKER" -e BATCH_SIZE="$BATCH_SIZE" \
    -e BENCHMARK_ES_HOST="$BENCHMARK_ES_HOST" -e BENCHMARK_ES_USER="$BENCHMARK_ES_USER" -e BENCHMARK_ES_PW="$BENCHMARK_ES_PW" \
    -e MONITOR_ES_HOST="$MONITOR_ES_HOST" -e MONITOR_ES_USER="$MONITOR_ES_USER" -e MONITOR_ES_PW="$MONITOR_ES_PW" \
    -v $LS_CONFIG_PATH/logstash.yml:/usr/share/logstash/config/logstash.yml:ro \
    -v $LS_CONFIG_PATH/pipelines.yml:/usr/share/logstash/config/pipelines.yml:ro \
    -v $LS_CONFIG_PATH/uuid:/usr/share/logstash/data/uuid:ro \
    docker.elastic.co/logstash/logstash:$LS_VERSION
}

remove_v9_config() {
  local config_path="$LS_CONFIG_PATH/logstash.yml"
  local major_version=$(echo $LS_VERSION | cut -d. -f1)
  if [ "$major_version" -lt 9 ]; then
    echo "Remove v9 config 'xpack.monitoring.allow_legacy_collection' from logstash.yml"

    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' '/xpack\.monitoring\.allow_legacy_collection/d' "$config_path"
    else
      sed -i '/xpack\.monitoring\.allow_legacy_collection/d' "$config_path"
    fi
  fi
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

  # build json
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
  SUMMARY="{\"timestamp\": \"$timestamp\", \"version\": \"$LS_VERSION\", \"cpu\": \"$CPU\", \"mem\": \"$MEM\", \"workers\": \"$WORKER\", \"batch_size\": \"$BATCH_SIZE\", \"queue_type\": \"$QTYPE\""
  not_empty "$TOTAL_EVENTS_OUT" && SUMMARY="$SUMMARY, \"total_events_out\": \"$TOTAL_EVENTS_OUT\""
  not_empty "$MAX_EPS_1M" && SUMMARY="$SUMMARY, \"max_eps_1m\": \"$MAX_EPS_1M\""
  not_empty "$MAX_EPS_5M" && SUMMARY="$SUMMARY, \"max_eps_5m\": \"$MAX_EPS_5M\""
  not_empty "$MAX_WORKER_UTIL" && SUMMARY="$SUMMARY, \"max_worker_utilization\": \"$MAX_WORKER_UTIL\""
  not_empty "$MAX_WORKER_CONCURR" && SUMMARY="$SUMMARY, \"max_worker_concurrency\": \"$MAX_WORKER_CONCURR\""
  not_empty "$AVG_CPU_PERCENT" && SUMMARY="$SUMMARY, \"avg_cpu_percentage\": \"$AVG_CPU_PERCENT\""
  not_empty "$AVG_HEAP" && SUMMARY="$SUMMARY, \"avg_heap\": \"$AVG_HEAP\""
  not_empty "$AVG_NON_HEAP" && SUMMARY="$SUMMARY, \"avg_non_heap\": \"$AVG_NON_HEAP\""
  not_empty "$AVG_VIRTUAL_MEM" && SUMMARY="$SUMMARY, \"avg_virtual_memory\": \"$AVG_VIRTUAL_MEM\""
  not_empty "$MAX_Q_EVENT_CNT" && SUMMARY="$SUMMARY, \"max_queue_events\": \"$MAX_Q_EVENT_CNT\""
  not_empty "$MAX_Q_SIZE" && SUMMARY="$SUMMARY, \"max_queue_bytes_size\": \"$MAX_Q_SIZE\""
  not_empty "$TAGS" && SUMMARY="$SUMMARY, \"tags\": $JSON_TAGS"
  SUMMARY="$SUMMARY}"

  tee summary.json << EOF
{"index": {}}
$SUMMARY
EOF

  # send to ES
  local resp
  local err_status
  resp=$(curl -s -X POST -u "$BENCHMARK_ES_USER:$BENCHMARK_ES_PW" "$BENCHMARK_ES_HOST/benchmark_summary/_bulk" -H 'Content-Type: application/json' --data-binary @"summary.json")
  echo "$resp"
  err_status=$(echo "$resp" | jq -r ".errors")
  if [[ "$err_status" == "true" ]]; then
    echo "Failed to send summary"
    exit 1
  fi
}

# $1: snapshot index
node_stats() {
  NS_JSON="$SCRIPT_PATH/$NS_DIR/${QTYPE:0:1}_w${WORKER}b${BATCH_SIZE}_$1.json" # m_w8b1000_0.json

  # curl inside container because docker on mac cannot resolve localhost to host network interface
  docker exec -i ls curl localhost:9600/_node/stats > "$NS_JSON" 2> /dev/null
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

clean_up() {
  # stop log generation if it has not done yet
  [[ -n $(docker ps | grep flog) ]] && docker stop flog || true
  # remove image
  docker image rm docker.elastic.co/logstash/logstash:$LS_VERSION
}
