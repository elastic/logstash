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
  if java.lang.System.getProperty("org.bouncycastle.fips.approved_only") == "true"
    c.filter_run_excluding skip_fips: true
  end
end