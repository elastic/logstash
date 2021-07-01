# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative "../spec_helper"
require_relative "../../../../qa/integration/services/monitoring_api"

describe "GeoIP database service" do
  let(:input) { "input { generator { lines => ['{\\\"host\\\": \\\"0.42.56.104\\\"}'] } } " }
  let(:output) { "output { null {} }" }
  let(:filter) { " " }
  let(:config) { input + filter + output }

  context "monitoring API with geoip plugin" do
    let(:filter) do
      "filter { json { source => \\\"message\\\" } geoip { source => \\\"host\\\" target => \\\"geoip\\\" } } "
    end

    it "should have geoip" do
      start_logstash
      api = MonitoringAPI.new
      stats = api.node_stats

      expect(stats["geoip_download_manager"]).not_to be_nil
    end
  end

  context "monitoring API without geoip plugin" do
    it "should not have geoip" do
      start_logstash
      api = MonitoringAPI.new
      stats = api.node_stats

      expect(stats["geoip_download_manager"]).to be_nil
    end
  end

  def start_logstash
    @logstash_service = logstash("bin/logstash -e \"#{config}\" -w 1", {
      :belzebuth => {
        :wait_condition => /Pipelines running/, # Check for all pipeline started
        :timeout => 5 * 60 # Fail safe, this mean something went wrong if we hit this before the wait_condition
      }
    })
  end

  after(:each) do
    @logstash_service.stop unless @logstash_service.nil?
  end
end
