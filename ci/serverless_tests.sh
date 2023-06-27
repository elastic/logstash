#!/usr/bin/env bash
set -ex

vault_path=secret/ci/elastic-logstash/serverless-test
# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export SERVERLESS=true
export ES_ENDPOINT=$(vault read -field=host "${vault_path}")
export ES_USER=$(vault read -field=super_user "${vault_path}")
export ES_PW=$(vault read -field=super_user_pw "${vault_path}")

./gradlew clean bootstrap assemble installDefaultGems unpackTarDistribution :logstash-core:copyGemjar

jruby -rbundler/setup -S rspec -fd qa/integration/specs/es_output_how_spec.rb
jruby -rbundler/setup -S rspec -fd qa/integration/specs/dlq_spec.rb