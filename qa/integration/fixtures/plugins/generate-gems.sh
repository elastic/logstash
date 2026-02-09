#!/usr/bin/env sh
# Add jruby bin directory to the PATH before existing entries so vendored gem takes priority over rbenv shims
SCRIPT_DIR="$( dirname "$0" )"
PATH="$SCRIPT_DIR/../../../../vendor/jruby/bin:$PATH"
export PATH

# Use only vendored JRuby's environment; avoid RVM/rbenv GEM_PATH so RubyGems
# does not load plugins (e.g. gem-wrappers) that require gems not in the test bundle.
unset GEM_PATH
unset GEM_HOME

cd "$SCRIPT_DIR"
find . -name '*.gemspec' | xargs -n1 gem build