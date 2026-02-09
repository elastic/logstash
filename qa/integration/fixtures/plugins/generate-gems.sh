#!/usr/bin/env sh
# Add jruby bin directory to the PATH before existing entries so vendored gem takes priority over rbenv shims
SCRIPT_DIR="$( dirname "$0" )"
PATH="$SCRIPT_DIR/../../../../vendor/jruby/bin:$PATH"
export PATH

cd "$SCRIPT_DIR"
find . -name '*.gemspec' | xargs -n1 gem build