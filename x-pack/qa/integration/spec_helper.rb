# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

MONITORING_INDEXES = ".monitoring-logstash-*"

require_relative "support/helpers"
require_relative "support/shared_examples"
require_relative "support/elasticsearch/api/actions/update_password"
require "json"
require "json-schema"

RSpec.configure do |c|
  # Exclude skip_fips examples when running under a FIPS-configured JVM.
  # Detection uses BCFIPS provider presence rather than approved_only since
  # we run C:HYBRID mode which does not set approved_only=true.
  if !java.security.Security.getProvider("BCFIPS").nil?
    c.filter_run_excluding skip_fips: true
  end
end