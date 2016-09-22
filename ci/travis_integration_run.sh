#!/usr/bin/env bash
set -e

if [[ "$INTEGRATION" != "true" ]]; then
    exit
fi

echo "Running integration tests from qa/integration directory"
cd qa/integration
rspec
