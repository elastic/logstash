#!/bin/bash
set -e
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"
stop_es
