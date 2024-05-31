#!/usr/bin/env bash
set -euo pipefail

main() {
    echo "hello world"
    echo "$@"
}

main "$@"