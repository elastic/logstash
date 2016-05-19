#!/usr/bin/env bash
set -e

##
# Note this setup needs a system ruby to be available, this can not
# be done here as is higly system dependant.
##

#squid proxy work, so if there is a proxy it can be cached.
sed -i.bak 's/https:/http:/' Gemfile

# Clean up some  possible stale directories
rm -rf vendor       # make sure there are no vendorized dependencies
rm -rf .bundle
rm -rf spec/reports # no stale spec reports from previous executions

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

# Setup the environment
rake bootstrap # Bootstrap your logstash instance

# Set up some general options for the rspec runner
echo "--order rand" > .rspec
echo "--format progress" >> .rspec
echo "--format CI::Reporter::RSpecFormatter" >> .rspec
