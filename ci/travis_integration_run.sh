#!/usr/bin/env bash
set -e

echo "Running integration tests from qa/integration directory"
cd qa/integration

# The offline specs can break the online ones
# due to some sideeffects of the seccomp policy interfering with
# the docker daemon
# See prepare_offline_pack_spec.rb for details
bin/rspec --tag ~offline
bin/rspec --tag offline
