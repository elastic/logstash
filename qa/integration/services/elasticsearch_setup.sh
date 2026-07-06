#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

ES_HOME="$current_dir/../../../build/elasticsearch"

ES_DATA_PATH="/tmp/ls_integration/es-data"
ES_LOGS_PATH="/tmp/ls_integration/es-logs"
ES_PID_FILE="$ES_HOME/elasticsearch.pid"

if [ -n "$ES_TLS_CERT" ]; then
  # Check for HTTP response (curl exits 0 even on 401); auth is set after startup
  ES_HEALTH_CMD="curl --silent --insecure https://localhost:9200"
else
  ES_HEALTH_CMD="curl --silent http://localhost:9200"
fi

start_es() {
  es_args=$@
  mkdir -p $ES_DATA_PATH $ES_LOGS_PATH
  JAVA_HOME= $ES_HOME/bin/elasticsearch -Epath.data=$ES_DATA_PATH -Ediscovery.type=single-node -Epath.logs=$ES_LOGS_PATH $es_args -p $ES_PID_FILE > /tmp/elasticsearch.log 2>/dev/null &
  count=120
  echo "Waiting for elasticsearch to respond..."
  while ! $ES_HEALTH_CMD && [[ $count -ne 0 ]]; do
      count=$(( $count - 1 ))
      [[ $count -eq 0 ]] && cat /tmp/elasticsearch.log && return 1
      sleep 1
  done
  echo "Elasticsearch is Up !"
  return 0
}

export ES_JAVA_OPTS="-Xms512m -Xmx512m"

if [ -n "$ES_TLS_CERT" ]; then
  # ES 9.x entitlement only allows reading cert files from $ES_HOME/config/
  cp "$ES_TLS_CERT" "$ES_HOME/config/es-server.crt"
  cp "$ES_TLS_KEY"  "$ES_HOME/config/es-server.key"
  cp "$ES_TLS_CA"   "$ES_HOME/config/es-ca.crt"

  start_es \
    -Expack.security.enabled=true \
    -Expack.security.http.ssl.enabled=true \
    -Expack.security.http.ssl.certificate=es-server.crt \
    -Expack.security.http.ssl.key=es-server.key \
    -Expack.security.http.ssl.certificate_authorities=es-ca.crt \
    -Ehttp.port=9200

  # Use a file-realm superuser for all TLS connections (avoids native-realm bootstrap).
  $ES_HOME/bin/elasticsearch-users userdel esadmin 2>/dev/null || true
  $ES_HOME/bin/elasticsearch-users useradd esadmin -p esadmin123 -r superuser
else
  start_es -Expack.security.enabled=false
fi
