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

describe "Test Logstash instance whose default settings are overridden" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    @logstash_service = @fixture.get_service("logstash")
    @logstash_default_logs = File.join(@logstash_service.logstash_home, "logs", "logstash-plain.log")
  }

  after(:all) {
    @fixture.teardown
  }

  before(:each) {
    FileUtils.rm(@logstash_default_logs) if File.exist?(@logstash_default_logs)
    # backup the application settings file -- logstash.yml
    FileUtils.cp(@logstash_service.application_settings_file, "#{@logstash_service.application_settings_file}.original")
  }

  after(:each) {
    @logstash_service.teardown
    # restore the application settings file -- logstash.yml
    FileUtils.mv("#{@logstash_service.application_settings_file}.original", @logstash_service.application_settings_file)
  }

  let(:num_retries) { 50 }
  let(:test_port) { random_port }
  let(:temp_dir) { Stud::Temporary.directory("logstash-settings-test") }
  let(:tcp_config) { @fixture.config("root", { :port => test_port }) }

  def change_setting(name, value)
    settings = {}
    settings[name] = value
    overwrite_settings(settings)
  end

  def overwrite_settings(settings)
    IO.write(@logstash_service.application_settings_file, settings.to_yaml)
  end

  it "should start with a new data dir" do
    change_setting("path.data", temp_dir)
    @logstash_service.spawn_logstash("-e", tcp_config)
    @logstash_service.wait_for_logstash
    # check LS is up and running with new data path
    try(num_retries) do
      expect(is_port_open?(test_port)).to be true
    end
  end

  it "should write logs to a new dir" do
    change_setting("path.logs", temp_dir)
    @logstash_service.spawn_logstash("-e", tcp_config)
    @logstash_service.wait_for_logstash
    # check LS is up and running with new data path
    try(num_retries) do
      expect(is_port_open?(test_port)).to be true
    end
    expect(File.exist?("#{temp_dir}/logstash-plain.log")).to be true
  end

  it "should read config from the specified dir in logstash.yml" do
    change_setting("path.config", temp_dir)
    test_config_path = File.join(temp_dir, "test.config")
    IO.write(test_config_path, tcp_config)
    expect(File.exist?(test_config_path)).to be true
    @logstash_service.spawn_logstash
    @logstash_service.wait_for_logstash
    # check LS is up and running with new data path
    try(num_retries) do
      expect(is_port_open?(test_port)).to be true
    end
  end

  it "should exit when config test_and_exit is set" do
    test_config_path = File.join(temp_dir, "test.config")
    IO.write(test_config_path, "#{tcp_config}")
    expect(File.exist?(test_config_path)).to be true
    s = {}
    s["path.config"] = test_config_path
    s["config.test_and_exit"] = true
    s["path.logs"] = temp_dir
    overwrite_settings(s)
    @logstash_service.spawn_logstash
    try(num_retries) do
      expect(@logstash_service.exited?).to be true
    end
    expect(@logstash_service.exit_code).to eq(0)

    # now with bad config
    IO.write(test_config_path, "#{tcp_config} filters {} ")
    expect(File.exist?(test_config_path)).to be true
    @logstash_service.spawn_logstash
    try(num_retries) do
      expect(@logstash_service.exited?).to be true
    end
    expect(@logstash_service.exit_code).to eq(1)
  end

  it "change pipeline settings" do
    s = {}
    workers = 31
    batch_size = 1
    s["pipeline.workers"] = workers
    s["pipeline.batch.size"] = batch_size
    overwrite_settings(s)
    @logstash_service.spawn_logstash("-e", tcp_config)
    @logstash_service.wait_for_logstash
    # check LS is up and running with new data path
    try(num_retries) do
      expect(is_port_open?(test_port)).to be true
    end

    # now check monitoring API to validate
    node_info = @logstash_service.monitoring_api.node_info
    expect(node_info["pipelines"]["main"]["workers"]).to eq(workers)
    expect(node_info["pipelines"]["main"]["batch_size"]).to eq(batch_size)
  end

  it "start on a different HTTP port" do
    # default in 9600
    http_port = random_port
    change_setting("api.http.port", http_port)
    @logstash_service.spawn_logstash("-e", tcp_config)
    wait_for_port(http_port, 60)
    expect(is_port_open?(http_port)).to be true
    # check LS is up and running with new data path
    try(num_retries) do
      expect(is_port_open?(test_port)).to be true
    end

    expect(File.exist?(@logstash_default_logs)).to be true

    resp = Manticore.get("http://localhost:#{http_port}/_node").body
    node_info = JSON.parse(resp)
    # should be default
    expect(node_info["http_address"]).to eq("127.0.0.1:#{http_port}")
  end

  it "start even without a settings file specified" do
    @logstash_service.spawn_logstash("-e", tcp_config, "--path.settings", "/tmp/fooooobbaaar")
    @logstash_service.wait_for_logstash
    http_port = 9600
    try(num_retries) do
      expect(is_port_open?(http_port)).to be true
    end

    try(num_retries) do
      expect(is_port_open?(test_port)).to be true
    end

    resp = Manticore.get("http://localhost:#{http_port}/_node").body
    node_info = JSON.parse(resp)
    expect(node_info["http_address"]).to eq("127.0.0.1:#{http_port}")

    # make sure we log to console and not to any file
    expect(File.exist?(@logstash_default_logs)).to be false
  end
end
