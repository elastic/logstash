#!/usr/bin/env bash
set -e

cd qa/integration
bundle exec rspec -fd --tag ~offline $@
bundle exec rspec -fd --tag offline $@