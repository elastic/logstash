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

describe "Test Logstash Pipeline id" do
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

  it "should not create separate pipelines log files if not enabled" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name,
      "pipeline.separate_logs" => false
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-e", config)
    wait_logstash_process_terminate

    deprecation_log_file = "#{temp_dir}/logstash-deprecation.log"
    expect(File.exist?(deprecation_log_file)).to be true
    deprecation_log_content = IO.read(deprecation_log_file)
    expect(deprecation_log_content =~ /\[deprecation.logstash.filters.ruby\].*Teleport/).to be > 0
  end

  @private
  def wait_logstash_process_terminate
    num_retries = 100
    try(num_retries) do
      expect(@ls.exited?).to be(true)
    end
    expect(@ls.exit_code).to be >= 0
  end
end
