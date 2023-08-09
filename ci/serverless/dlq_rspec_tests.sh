#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

export JRUBY_OPTS="-J-Xmx1g"
export SERVERLESS=true
setup_vault

./gradlew clean bootstrap assemble installDefaultGems unpackTarDistribution
./gradlew :logstash-core:copyGemjar

export GEM_PATH=vendor/bundle/jruby/3.1.0
export GEM_HOME=vendor/bundle/jruby/3.1.0

vendor/jruby/bin/jruby -S bundle install --with development

vendor/jruby/bin/jruby -S bundle exec rspec -fd qa/integration/specs/dlq_spec.rb -e "using pipelines.yml"
