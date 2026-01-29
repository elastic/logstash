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

# SPLIT_ESTIMATE: 20
describe "Logstash to Logstash communication Integration test" do

  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  def get_temp_path_dir
    tmp_path = Stud::Temporary.pathname
    tmp_data_path = File.join(tmp_path, "data")
    FileUtils.mkdir_p(tmp_data_path)
    tmp_data_path
  end

  def run_logstash_instance(config_name, options = {}, &block)
    @next_api_port_offset = (@next_api_port_offset||100).next.modulo(1000) # cycle through 1000 possibles
    api_port = 9600 + @next_api_port_offset

    # to avoid LogstashService's clean-from-tarball default behaviour, we need
    # to tell it where our LOGSTASH_HOME is in the existing service
    existing_fixture_logstash_home = @fixture.get_service("logstash").logstash_home
    logstash_service = LogstashService.new(@fixture.settings.override("ls_home_abs_path" => existing_fixture_logstash_home), api_port)

    logstash_service.spawn_logstash("--node.name", config_name,
                                    "--pipeline.id", config_name,
                                    "--path.config", config_to_temp_file(@fixture.config(config_name, options)),
                                    "--path.data", get_temp_path_dir,
                                    "--api.http.port", api_port.to_s,
                                    "--config.reload.automatic")
    logstash_service.wait_for_rest_api
    yield logstash_service
  ensure
    logstash_service.teardown
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
      run_logstash_instance(input_config_name, all_config_options) do |downstream_logstash_service|
        run_logstash_instance(output_config_name, all_config_options) do |upstream_logstash_service|

          try(num_retries) do
            downstream_event_stats = downstream_logstash_service.monitoring_api.event_stats
            expect(downstream_event_stats).to include({"in" => num_events}), lambda { "expected #{num_events} events to have been received by downstream" }
            expect(downstream_event_stats).to include({"out" => num_events}), lambda { "expected #{num_events} events to have been processed by downstream" }
          end

          # make sure received events are in the file
          file_output_path = File.join(downstream_logstash_service.logstash_home, output_file_path_with_datetime)
          expect(File).to exist(file_output_path), "Logstash to Logstash output file: #{file_output_path} does not exist"
          actual_lines = File.read(file_output_path).lines.to_a
          expected_lines = (0...num_events).map { |sequence| "#{sequence}:Hello world!\n" }
          expect(actual_lines).to match_array(expected_lines)

          File.delete(file_output_path)
        end
      end
    end
  end

  context "with baseline configs" do
    let(:input_config_name) { "basic_ls_input" }
    let(:output_config_name) { "basic_ls_output" }
    let(:output_file_path) { "basic_ls_to_ls.output" }

    include_examples "send events"
  end

end
