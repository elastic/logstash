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

# Setup the environment
rake bootstrap # Bootstrap your logstash instance

# Set up some general options for the rspec runner
echo "--order rand" > .rspec
echo "--format progress" >> .rspec
echo "--format CI::Reporter::RSpecFormatter" >> .rspec
