#!/usr/bin/env bash
set -eo pipefail

../common/generate-main-test-steps.sh --enable-sonar | buildkite-agent pipeline upload
