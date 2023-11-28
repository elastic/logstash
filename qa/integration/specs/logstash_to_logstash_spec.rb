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
require_relative '../framework/helpers'
require_relative '../services/logstash_service'

require 'stud/temporary'
require 'logstash/devutils/rspec/spec_helper'

describe "Logstash to Logstash communication Integration test" do

  before(:all) {
    @fixture = Fixture.new(__FILE__)
    # backup original setting file since we change API port number, and restore after all tests
    FileUtils.cp(@fixture.get_service('logstash').application_settings_file, "#{@fixture.get_service('logstash').application_settings_file}.original")
  }

  after(:all) {
    FileUtils.mv("#{@fixture.get_service('logstash').application_settings_file}.original", @fixture.get_service('logstash').application_settings_file)
    @fixture.teardown
  }

  def change_logstash_setting(logstash_service, name, value)
    settings = {}.tap do |settings|
      settings[name] = value
    end
    IO.write(logstash_service.application_settings_file, settings.to_yaml)
  end

  def get_temp_path_dir
    tmp_path = Stud::Temporary.pathname
    tmp_data_path = File.join(tmp_path, "data")
    FileUtils.mkdir_p(tmp_data_path)
    tmp_data_path
  end

  def run_logstash_instance(config_name, options = {})
    api_port = 9600 + rand(1000)
    logstash_service = LogstashService.new(@fixture.settings, api_port)
    change_logstash_setting(logstash_service, "api.http.port", api_port)
    logstash_service.spawn_logstash("-f", config_to_temp_file(@fixture.config(config_name, options)), "--path.data", get_temp_path_dir)
    wait_for_logstash(logstash_service)
    logstash_service
  end

  def wait_for_logstash(service)
    wait_in_seconds = 60
    while wait_in_seconds > 0 do
      begin
        return if service.rest_active?
      rescue => e
        puts "Exception: #{e.message}"
        wait_in_seconds -= 1
        sleep 1
      end
    end
    raise "Logstash is not responsive after 60 seconds."
  end

  let(:num_retries) { 60 }
  let(:num_events) { 1003 }
  let(:config_options) {
    { :generator_count => num_events }
  }

  shared_examples "send events" do
    let(:output_file_path_with_datetime) { "#{output_file_path}_#{DateTime.now.new_offset(0).strftime('%Y_%m_%d_%H_%M_%S')}" }
    let(:all_config_options) {
      config_options.merge({ :output_file_path => output_file_path_with_datetime })
    }

    it "successfully send events" do
      upstream_logstash_service = run_logstash_instance(input_config_name, all_config_options)
      downstream_logstash_service = run_logstash_instance(output_config_name, all_config_options)

      try(num_retries) do
        event_stats = upstream_logstash_service.monitoring_api.event_stats
        if event_stats
          expect(event_stats["in"]).to eq(num_events)
        end
      end

      upstream_logstash_service.teardown
      downstream_logstash_service.teardown

      # make sure received events are in the file
      file_output_path = File.join(upstream_logstash_service.logstash_home, output_file_path_with_datetime)
      expect(File).to exist(file_output_path), "Logstash to Logstash output file: #{file_output_path} does not exist"
      count = File.foreach(file_output_path).inject(0) { |c, _| c + 1 }
      expect(count).to eq(num_events)

      File.delete(file_output_path)
    end
  end

  context "with baseline configs" do
    let(:input_config_name) { "basic_ls_input" }
    let(:output_config_name) { "basic_ls_output" }
    let(:output_file_path) { "basic_ls_to_ls.output" }

    include_examples "send events"
  end

end