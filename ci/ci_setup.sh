#!/usr/bin/env bash

#squid proxy work, so if there is a proxy it can be cached.
sed -i.bak 's/https:/http:/' tools/Gemfile

# Clean up some  possible stale directories
rm -rf vendor       # make sure there are no vendorized dependencies
rm -rf spec/reports # no stale spec reports from previous executions

# Setup the environment
rake bootstrap # Bootstrap your logstash instance
