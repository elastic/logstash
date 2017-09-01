#!/usr/bin/env bash
set -e

cd qa/integration
bundle exec rspec --tag ~offline $@
bundle exec rspec --tag offline $@