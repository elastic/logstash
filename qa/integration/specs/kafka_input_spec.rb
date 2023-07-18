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

  before(:all) do
    @fixture = Fixture.new(__FILE__)
  end

  after(:all) do
    @fixture.teardown unless @fixture.nil?
  end

  let(:logstash_service) do
    @fixture.get_service("logstash")
  end

  let(:file_output_path) do
    # output { file { path => "..." } } is LS_HOME relative
    File.join(logstash_service.logstash_home, @fixture.actual_output)
  end

  before do
    logstash_service.start_background(@fixture.config)
    sleep(0.5)
  end

  after do
    File.delete(file_output_path) if File.exist?(file_output_path)
  end

  it "can ingest 37 apache log lines from Kafka broker" do
    try(num_retries) do
      expect(File).to exist(file_output_path), "output file: #{file_output_path} does not exist"
    end

    try(num_retries) do
      count = File.foreach(file_output_path).inject(0) {|c, _| c + 1}
      expect(count).to eq(num_events)
    end
  end
end
