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
require "stud/temporary"
require "stud/try"
require "rspec/wait"
require "yaml"
require "fileutils"
require "logstash/devutils/rspec/spec_helper"

describe "Ruby codec when used in" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  before(:each) {
    # backup the application settings file -- logstash.yml
    FileUtils.cp(logstash_service.application_settings_file, "#{logstash_service.application_settings_file}.original")
    IO.write(logstash_service.application_settings_file, settings.to_yaml)
  }

  after(:each) {
    logstash_service.teardown
    # restore the application settings file -- logstash.yml
    FileUtils.mv("#{logstash_service.application_settings_file}.original", logstash_service.application_settings_file)
  }

  let(:temp_dir) { Stud::Temporary.directory("logstash-pipelinelog-test") }
  let(:logstash_service) { @fixture.get_service("logstash") }
  let(:out_capture) { Tempfile.new("file_out") }
  let(:settings) do
    {"path.logs" => temp_dir }
  end

  context "input Java plugin" do
    let(:config) { @fixture.config("input_decode") }

    it "should encode correctly to file and don't log any ERROR" do
      logstash_service.env_variables = {'PATH_TO_OUT' => out_capture.path}
      logstash_service.start_with_stdin(config)

      # wait for Logstash to fully start
      logstash_service.wait_for_rest_api

      logstash_service.write_to_stdin('{"project": "Teleport"}')
      sleep(2)

      logstash_service.teardown

      plainlog_file = "#{temp_dir}/logstash-plain.log"
      expect(File.exist?(plainlog_file)).to be true
      logs = IO.read(plainlog_file)
      expect(logs).to_not include("ERROR")

      out_capture.rewind
      expect(out_capture.read).to include("\"project\":\"Teleport\"")
    end
  end

  context "input Java plugin with configured codec" do
    let(:config) { @fixture.config("input_decode_configured") }

    it "should encode correctly to file and don't log any ERROR" do
      logstash_service.env_variables = {'PATH_TO_OUT' => out_capture.path}
      logstash_service.spawn_logstash("-w", "1", "-e", config)
      logstash_service.wait_for_logstash
      logstash_service.wait_for_rest_api

      logstash_service.write_to_stdin('Teleport ray')
      sleep(2)

      logstash_service.teardown

      plainlog_file = "#{temp_dir}/logstash-plain.log"
      expect(File.exist?(plainlog_file)).to be true
      logs = IO.read(plainlog_file)
      expect(logs).to_not include("ERROR")

      out_capture.rewind
      expect(out_capture.read).to include("Teleport ray")
    end
  end

  context "output Java plugin" do
    let(:config) { @fixture.config("output_encode") }

    it "should encode correctly without any ERROR log" do
      logstash_service.spawn_logstash("-w", "1", "-e", config)
      logstash_service.wait_for_logstash
      logstash_service.wait_for_rest_api

      logstash_service.teardown

      plainlog_file = "#{temp_dir}/logstash-plain.log"
      expect(File.exist?(plainlog_file)).to be true
      logs = IO.read(plainlog_file)
      expect(logs).to_not include("ERROR")
    end
  end
end
