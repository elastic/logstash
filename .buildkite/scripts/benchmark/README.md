## Steps to set up GCP instance to run benchmark script
- Create an instance "n2-standard-16" with Ubuntu image
- Install docker
  - `sudo snap install docker`
  - `sudo usermod -a -G docker $USER`
- Install jq
- Install vault
  - `sudo snap install vault`
  - `vault login --method github`
  - `vault kv get -format json secret/ci/elastic-logstash/benchmark`
- Setup Elasticsearch index mapping and alias with `setup/*`
- Import Kibana dashboard with `save-objects/*`
- Run the benchmark script
  - Send data to your own Elasticsearch. Customise `VAULT_PATH="secret/ci/elastic-logstash/your/path"`
  - Run the script `main.sh` 
    - or run in background `nohup bash -x main.sh > log.log 2>&1 &`

## Notes
- Benchmarks should only be compared using the same hardware setup.
- Please do not send the test metrics to the benchmark cluster. You can set `VAULT_PATH` to send data and metrics to your own server.
- Run `all.sh` as calibration which gives you a baseline of performance in different versions.
- [#16586](https://github.com/elastic/logstash/pull/16586) allows legacy monitoring using the configuration `xpack.monitoring.allow_legacy_collection: true`, which is not recognized in version 8. To run benchmarks in version 8, use the script of the corresponding branch (e.g. `8.16`) instead of `main` in buildkite.