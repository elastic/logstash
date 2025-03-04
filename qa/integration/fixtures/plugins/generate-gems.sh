#!/usr/bin/env sh
# Add jruby bin directory to the PATH after existing entries for gem executable
SCRIPT_DIR="$( dirname "$0" )"
PATH="$PATH:$SCRIPT_DIR/../../../../vendor/jruby/bin"
export PATH

cd "$SCRIPT_DIR"
find . -name '*.gemspec' | xargs -n1 gem build