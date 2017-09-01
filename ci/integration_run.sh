#!/bin/bash -iex

cd qa/integration
echo "Running spec files $@"
bundle exec rspec -fd --tag ~offline $@
bundle exec rspec -fd --tag offline $@