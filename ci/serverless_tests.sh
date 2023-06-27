#!/usr/bin/env bash
set -ex

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export SERVERLESS=true
export ES_ENDPOINT=
export ES_USER=
export ES_PW=

./gradlew clean bootstrap assemble installDefaultGems unpackTarDistribution :logstash-core:copyGemjar

jruby -rbundler/setup -S rspec -fd qa/integration/specs/es_output_how_spec.rb
jruby -rbundler/setup -S rspec -fd qa/integration/specs/dlq_spec.rb