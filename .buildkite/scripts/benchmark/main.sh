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

SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_PATH/core.sh"

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
##   FLOG_FILE_CNT=4            # number of files to generate for ingestion
##   VAULT_PATH=secret/path     # vault path point to Elasticsearch credentials. The default value points to benchmark cluster.
##   TAGS=test,other            # tags with "," separator.
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

  clean_up
}

main "$@"