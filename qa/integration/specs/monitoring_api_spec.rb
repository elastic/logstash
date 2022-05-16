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
require "logstash/devutils/rspec/spec_helper"
require "stud/try"

describe "Test Monitoring API" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }
  
  after(:each) {
    @fixture.get_service("logstash").teardown
  }
  
  let(:number_of_events) { 5 }
  let(:max_retry) { 120 }

  it "can retrieve event stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash
    number_of_events.times { logstash_service.write_to_stdin("Hello world") }

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # event_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.event_stats rescue nil
      expect(result).not_to be_nil
      expect(result["in"]).to eq(number_of_events)
    end
  end

  context "queue draining" do
    let(:tcp_port) { random_port }
    let(:settings_dir) { Stud::Temporary.directory }
    let(:queue_config) {
      {
        "queue.type" => "persisted",
        "queue.drain" => true
      }
    }
    let(:config_yaml) { queue_config.to_yaml }
    let(:config_yaml_file) { ::File.join(settings_dir, "logstash.yml") }
    let(:logstash_service) { @fixture.get_service("logstash") }
    let(:config) { @fixture.config("draining_events", { :port => tcp_port }) }

    before(:each) do
      if logstash_service.settings.feature_flag == "persistent_queues"
        IO.write(config_yaml_file, config_yaml)
        logstash_service.spawn_logstash("-e", config, "--path.settings", settings_dir)
      else
        logstash_service.spawn_logstash("-e", config)
      end
      logstash_service.wait_for_logstash
      wait_for_port(tcp_port, 60)
    end

    it "can update metrics" do
      first = logstash_service.monitoring_api.event_stats
      Process.kill("TERM", logstash_service.pid)
      try(max_retry) do
        second = logstash_service.monitoring_api.event_stats
        expect(second["filtered"].to_i > first["filtered"].to_i).to be_truthy
      end
      Process.kill("KILL", logstash_service.pid)
    end
  end

  context "verify global event counters" do
    let(:tcp_port) { random_port }
    let(:sample_data) { 'Hello World!' }
    let(:logstash_service) { @fixture.get_service("logstash") }

    before(:each) do
      logstash_service.spawn_logstash("-w", "1" , "-e", config)
      logstash_service.wait_for_logstash
      wait_for_port(tcp_port, 60)

      send_data(tcp_port, sample_data)
    end

    context "when a drop filter is in the pipeline" do
      let(:config) { @fixture.config("dropping_events", { :port => tcp_port } ) }

      it 'expose the correct output counter' do
        try(max_retry) do
          # node_stats can fail if the stats subsystem isn't ready
          result = logstash_service.monitoring_api.node_stats rescue nil
          expect(result).not_to be_nil
          expect(result["events"]).not_to be_nil
          expect(result["events"]["in"]).to eq(1)
          expect(result["events"]["filtered"]).to eq(1)
          expect(result["events"]["out"]).to eq(0)
        end
      end
    end

    context "when a clone filter is in the pipeline" do
      let(:config) { @fixture.config("cloning_events", { :port => tcp_port } ) }

      it 'expose the correct output counter' do
        try(max_retry) do
          # node_stats can fail if the stats subsystem isn't ready
          result = logstash_service.monitoring_api.node_stats rescue nil
          expect(result).not_to be_nil
          expect(result["events"]).not_to be_nil
          expect(result["events"]["in"]).to eq(1)
          expect(result["events"]["filtered"]).to eq(1)
          expect(result["events"]["out"]).to eq(3)
        end
      end
    end
  end

  it "can retrieve JVM stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    try(max_retry) do
      # node_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.node_stats rescue nil
      expect(result).not_to be_nil
      expect(result["jvm"]).not_to be_nil
      expect(result["jvm"]["uptime_in_millis"]).to be > 100
    end
  end

  it 'can retrieve dlq stats' do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash
    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # node_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.node_stats rescue nil
      expect(result).not_to be_nil
      # we use fetch here since we want failed fetches to raise an exception
      # and trigger the retry block
      queue_stats = result.fetch('pipelines').fetch('main')['dead_letter_queue']
      if logstash_service.settings.get("dead_letter_queue.enable")
        expect(queue_stats['queue_size_in_bytes']).not_to be_nil
      else
        expect(queue_stats).to be nil
      end
    end
  end

  it "can retrieve queue stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # node_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.node_stats rescue nil
      expect(result).not_to be_nil
      # we use fetch here since we want failed fetches to raise an exception
      # and trigger the retry block
      queue_stats = result.fetch("pipelines").fetch("main").fetch("queue")
      expect(queue_stats).not_to be_nil
      if logstash_service.settings.feature_flag == "persistent_queues"
        expect(queue_stats["type"]).to eq "persisted"
        queue_data_stats = queue_stats.fetch("data")
        expect(queue_data_stats["free_space_in_bytes"]).not_to be_nil
        expect(queue_data_stats["storage_type"]).not_to be_nil
        expect(queue_data_stats["path"]).not_to be_nil
        expect(queue_stats["events"]).not_to be_nil
        queue_capacity_stats = queue_stats.fetch("capacity")
        expect(queue_capacity_stats["page_capacity_in_bytes"]).not_to be_nil
        expect(queue_capacity_stats["max_queue_size_in_bytes"]).not_to be_nil
        expect(queue_capacity_stats["max_unread_events"]).not_to be_nil
      else
        expect(queue_stats["type"]).to eq("memory")
      end
    end
  end

  it "can configure logging" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # monitoring api can fail if the subsystem isn't ready
      result = logstash_service.monitoring_api.logging_get rescue nil
      expect(result).not_to be_nil
      expect(result["loggers"].size).to be > 0
    end

    #default
    logging_get_assert logstash_service, "INFO", "TRACE",
                       skip: 'logstash.licensechecker.licensereader' #custom (ERROR) level to start with

    #root logger - does not apply to logger.slowlog
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger." => "WARN"})
    logging_get_assert logstash_service, "WARN", "TRACE"
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger." => "INFO"})
    logging_get_assert logstash_service, "INFO", "TRACE"

    #package logger
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash.agent" => "DEBUG"})
    expect(logstash_service.monitoring_api.logging_get["loggers"]["logstash.agent"]).to eq ("DEBUG")
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash.agent" => "INFO"})
    expect(logstash_service.monitoring_api.logging_get["loggers"]["logstash.agent"]).to eq ("INFO")

    #parent package loggers
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash" => "ERROR"})
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.slowlog" => "ERROR"})

    #deprecation package loggers
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.deprecation.logstash" => "ERROR"})

    result = logstash_service.monitoring_api.logging_get
    result["loggers"].each do | k, v |
      next if k.eql?("logstash.agent")
      #since we explicitly set the logstash.agent logger above, the logger.logstash parent logger will not take precedence
      if k.start_with?("logstash") || k.start_with?("slowlog") || k.start_with?("deprecation")
        expect(v).to eq("ERROR")
      end
    end

    # all log levels should be reset to original values
    logging_put_assert logstash_service.monitoring_api.logging_reset
    logging_get_assert logstash_service, "INFO", "TRACE"
  end

  private

  def logging_get_assert(logstash_service, logstash_level, slowlog_level, skip: '')
    result = logstash_service.monitoring_api.logging_get
    result["loggers"].each do | k, v |
      next if !k.empty? && k.eql?(skip)
      if k.start_with? "logstash", "org.logstash" #logstash is the ruby namespace, and org.logstash for java
        expect(v).to eq(logstash_level), "logstash logger '#{k}' has logging level: #{v} expected: #{logstash_level}"
      elsif k.start_with? "slowlog"
        expect(v).to eq(slowlog_level), "slowlog logger '#{k}' has logging level: #{v} expected: #{slowlog_level}"
      end
    end
  end

  def logging_put_assert(result)
    expect(result['acknowledged']).to be(true), "result not acknowledged, got: #{result.inspect}"
  end

end
