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
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

describe "Test Logstash configuration" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  let(:num_retries) { 50 }
  let(:test_tcp_port) { random_port }
  let(:test_tag) { "environment_variables_are_evil" }
  let(:test_path) { Stud::Temporary.directory }
  let(:sample_data) { '74.125.176.147 - - [11/Sep/2014:21:50:37 +0000] "GET /?flav=rss20 HTTP/1.1" 200 29941 "-" "FeedBurner/1.0 (http://www.FeedBurner.com)"' }

  it "expands environment variables in all plugin blocks" do
    # set ENV variables before starting the service
    test_env = {}
    test_env["TEST_ENV_TCP_PORT"] = "#{test_tcp_port}"
    test_env["TEST_ENV_TAG"] = test_tag
    test_env["TEST_ENV_PATH"] = test_path

    logstash_service = @fixture.get_service("logstash")
    logstash_service.env_variables = test_env
    logstash_service.start_background(@fixture.config)
    # check if TCP port env variable was resolved
    try(num_retries) do
      expect(is_port_open?(test_tcp_port)).to be true
    end

    #send data and make sure all env variables are expanded by checking each stage
    send_data(test_tcp_port, sample_data)
    output_file = File.join(test_path, "logstash_env_test.log")
    try(num_retries) do
      expect(File.exist?(output_file)).to be true
    end
    # should have created the file using env variable with filters adding a tag based on env variable
    try(num_retries) do
      expect(IO.read(output_file).gsub("\n", "")).to eq("#{sample_data} blah,environment_variables_are_evil")
    end
  end
end
