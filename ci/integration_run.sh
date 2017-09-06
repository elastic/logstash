#!/bin/bash -iex

cd qa/integration
echo "Running spec files $@"

rspec -fd --tag ~offline
rspec -fd --tag offline
