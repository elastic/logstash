# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative "../spec_helper"
require_relative "../../../../qa/integration/services/monitoring_api"

describe "GeoIP database service" do
  before :all do

    input = "input { generator { lines => ['{\\\"host\\\": \\\"0.42.56.104\\\"}'] } } "
    filter = "filter { json { source => \\\"message\\\" } geoip { source => \\\"host\\\" } } "
    output = "output { null {} }"
    config = input + filter + output

    @logstash_service = logstash("bin/logstash -e \"#{config}\" -w 1", {
      :belzebuth => {
        :wait_condition => /Pipelines running/, # Check for all pipeline started
        :timeout => 5 * 60 # Fail safe, this mean something went wrong if we hit this before the wait_condition
      }
    })
  end

  context "monitoring API" do
    it "should has geoip" do
      api = MonitoringAPI.new
      stats = api.node_stats
      expect(stats["geoip"]["database"]["City"]["fail_check_in_days"]).to eq(0)
      expect(stats["geoip"]["download"]["successes"]).to eq(1)
      expect(stats["geoip"]["download"]["status"]).to eq("succeeded")
    end
  end

  after :all do
    @logstash_service.stop unless @logstash_service.nil?
  end
end
