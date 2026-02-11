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
require "yaml"
require "manticore"

describe "Test Logstash buffer allocation setting" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    # used in multiple LS tests
    @ls = @fixture.get_service("logstash")
  }

  after(:all) {
    @fixture.teardown
  }

  before(:each) {
    # backup the application settings file -- logstash.yml
    FileUtils.cp(@ls.application_settings_file, "#{@ls.application_settings_file}.original")
  }

  after(:each) {
    @ls.teardown
    # restore the application settings file -- logstash.yml
    FileUtils.mv("#{@ls.application_settings_file}.original", @ls.application_settings_file)
  }

  let(:temp_dir) { Stud::Temporary.directory("logstash-pipelinelog-test") }
  let(:config) { @fixture.config("root") }
  let(:initial_config_file) { config_to_temp_file(@fixture.config("root")) }
  let(:settings) do
    {
      "path.logs" => temp_dir,
      "pipeline.buffer.type" => buffer_type
    }
  end

  context "running a pipeline that dump memory status" do
    before(:each) { start_logstash_and_process_some_events }

    context "when 'direct' is configured as pipeline.buffer.type" do
      let(:buffer_type) { "direct" }

      it "should use Netty direct memory" do
        last_dump_line = find_last_mem_dump_log_line("#{temp_dir}/logstash-plain.log")

        # verify direct buffer are used while heap buffers remains at 0
        direct_mem, heap_mem = last_dump_line.match(/\[logstash\.filters\.ruby\s*\]\[main\].*Direct pinned:\s*(\d*)\s*.*Heap pinned:\s*(\d*)/).captures
        expect(direct_mem.to_i).to be > 0
        expect(heap_mem.to_i).to eq 0
      end
    end

    context "when 'heap' is configured as pipeline.buffer.type" do
      let(:buffer_type) { "heap" }

      it "should use only Java heap memory" do
        last_dump_line = find_last_mem_dump_log_line("#{temp_dir}/logstash-plain.log")

        # verify java heap  buffer are used while direct buffers remains at 0
        direct_mem, heap_mem = last_dump_line.match(/\[logstash\.filters\.ruby\s*\]\[main\].*Direct pinned:\s*(\d*)\s*.*Heap pinned:\s*(\d*)/).captures
        expect(direct_mem.to_i).to eq 0
        expect(heap_mem.to_i).to be > 0
      end
    end
  end

  def start_logstash_and_process_some_events
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-e", config)

    Stud.try(120.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # poll Logstash HTTP api to become active
      expect(@ls.rest_active?).to be true
    end

    # wait main pipeline becomes active
    Stud.try(120.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      post_some_json_data
    end

    # wait some time to that the pipeline's Ruby filter allocate something with Netty allocator,
    # in the mean time some dumps should appear in the logs
    #(> 5 seconds because the JRuby filter in test pipeline dumps Netty memory status every 5 seconds)
    sleep 5
  end

  def find_last_mem_dump_log_line(log_file)
    log_content = load_log_file_content(log_file)

        # select just the log lines with memory dump
    return log_content.split(/\n/).select { |line| line =~ /\[logstash\.filters\.ruby\s*\]\[main\].*Direct pinned/ }.last
  end

  def load_log_file_content(log_file)
    expect(File.exist?(log_file)).to be true
    log_content = IO.read(log_file)
    return log_content
  end

  def post_some_json_data
    body = '{"firstKey": "somedata", "secondKey": "somedata"}'
    default_headers = {"Content-Type" => "application/json"}
    resp = Manticore.post("http://localhost:8080", {:body => body, :headers => default_headers})
    expect(resp.code).to eq 200
  end

end
