# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "rspec/wait"
require "logstash/devutils/rspec/spec_helper"

describe "Test Kafka Input" do
  let(:num_retries) { 60 }
  let(:num_events) { 37 }

  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown unless @fixture.nil?
  }

  it "can ingest 37 apache log lines from Kafka broker" do
    unless @fixture.nil?
      logstash_service = @fixture.get_service("logstash")
      logstash_service.start_background(@fixture.config)

      try(num_retries) do
        expect(@fixture.output_exists?).to be true
      end

      try(num_retries) do
        count = File.foreach(@fixture.actual_output).inject(0) {|c, _| c+1}
        expect(count).to eq(num_events)
      end
    end
  end
end
