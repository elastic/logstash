#!/usr/bin/env bash

pushd $(pwd)

cd /opt/buildkite-agent/filebeat
CLUSTER_CREDS_PATH_SECRET="kv/ci-shared/platform-ingest/buildkite-logs"

export API_KEY_SECRET=$(retry -t 5 -- vault kv get -field filebeat-apikey "${CLUSTER_CREDS_PATH_SECRET}")
export ES_ENDPOINT_SECRET=$(retry -t 5 -- vault kv get -field es-endpoint "${CLUSTER_CREDS_PATH_SECRET}")

echo ${ES_ENDPOINT_SECRET:0:13}
nohup ./filebeat --path.home $PWD --path.config $PWD -c filebeat.yml &

popd
