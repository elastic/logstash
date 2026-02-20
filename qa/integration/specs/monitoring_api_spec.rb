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
  before(:each) do |example|
    $stderr.puts("STARTING: #{example.full_description} (#{example.location})")
  end

  before(:all) {
    @fixture = Fixture.new(__FILE__)
    ruby_encoding_info = %w(external internal locale filesystem).map do |type|
      Encoding.find(type)&.name&.then { |name| "#{type}:#{name}" }
    end.compact.join(", ")

    $stderr.puts <<~ENCODINGINFO.tr("\n", ' ')
      INFO(spec runner process)
      Ruby.Encoding=(#{ruby_encoding_info})
      Java.Locale=`#{java.util.Locale::getDefault().toLanguageTag()}`
      Java.Charset=`#{java.nio.charset.Charset::defaultCharset().displayName()}`
    ENCODINGINFO
  }

  let(:settings_overrides) do
    {}
  end

  let(:logstash_service) { @fixture.get_service("logstash") }

  before(:each) do
    # some settings values cannot be reliably passed on the command line
    # because we are not guaranteed that the shell's encoding supports UTF-8.
    # Merge our settings into the active settings file, to accommodate feature flags
    unless settings_overrides.empty?
      settings_file = logstash_service.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      base_settings = YAML.load(File.read(settings_file)) || {}
      effective_settings = base_settings.merge(settings_overrides) do |key, old_val, new_val|
        warn "Overriding setting `#{key}` with `#{new_val}` (was `#{old_val}`)"
        new_val
      end

      IO.write(settings_file, effective_settings.to_yaml)
    end
  end

  after(:all) {
    @fixture.teardown
  }

  after(:each) do
    settings_file = logstash_service.application_settings_file
    logstash_service.teardown
    FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
  end

  let(:number_of_events) { 5 }
  let(:max_retry) { 120 }

  it "can retrieve event stats" do
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
    end
  end

  context "verify global event counters" do
    let(:tcp_port) { random_port }
    let(:sample_data) { 'Hello World!' }
    let(:logstash_service) { @fixture.get_service("logstash") }

    before(:each) do
      logstash_service.spawn_logstash("-w", "1", "-e", config)
      logstash_service.wait_for_logstash
      wait_for_port(tcp_port, 60)

      send_data(tcp_port, sample_data)
    end

    context "when a drop filter is in the pipeline" do
      let(:config) { @fixture.config("dropping_events", { :port => tcp_port }) }

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
      let(:config) { @fixture.config("cloning_events", { :port => tcp_port }) }

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

  it 'retrieves health report' do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash
    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # health_report can fail if the subsystem isn't ready
      result = logstash_service.monitoring_api.health_report rescue nil
      expect(result).not_to be_nil
      expect(result).to be_a(Hash)
      expect(result).to include("status")
      expect(result["status"]).to match(/^(green|yellow|red)$/)
    end
  end

  it 'retrieves node plugins information' do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash
    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # node_plugins can fail if the subsystem isn't ready
      result = logstash_service.monitoring_api.node_plugins rescue nil
      expect(result).not_to be_nil
      expect(result).to be_a(Hash)
      expect(result).to include("plugins")
      plugins = result["plugins"]
      expect(plugins).to be_a(Array)
      expect(plugins.size).to be > 0
      # verify plugin structure and that stdin plugin is present
      stdin_plugin = plugins.find { |p| p["name"] == "logstash-input-stdin" }
      expect(stdin_plugin).not_to be_nil
      expect(stdin_plugin).to include("name")
      expect(stdin_plugin["name"]).to eq("logstash-input-stdin")
      expect(stdin_plugin).to include("version")
    end
  end

  shared_examples "pipeline metrics" do
    # let(:pipeline_id) { defined?(super()) or fail NotImplementedError }
    let(:settings_overrides) do
      super().dup.tap do |overrides|
        overrides['pipeline.id'] = pipeline_id
        if logstash_service.settings.feature_flag == "persistent_queues"
          overrides['queue.compression'] = %w(none speed balanced size).sample
        end
      end
    end

    it "can retrieve queue stats" do
      logstash_service.start_with_stdin
      logstash_service.wait_for_logstash

      number_of_events.times {
        logstash_service.write_to_stdin("Testing flow metrics")
        sleep(1)
      }

      Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
        # node_stats can fail if the stats subsystem isn't ready
        result = logstash_service.monitoring_api.node_stats rescue nil
        expect(result).not_to be_nil
        # we use fetch here since we want failed fetches to raise an exception
        # and trigger the retry block
        queue_stats = result.fetch("pipelines").fetch(pipeline_id).fetch("queue")
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
          queue_compression_stats = queue_stats.fetch("compression")
          expect(queue_compression_stats.dig('decode', 'ratio', 'lifetime')).to be >= 1
          expect(queue_compression_stats.dig('decode', 'spend', 'lifetime')).not_to be_nil
          if settings_overrides['queue.compression'] != 'none'
            expect(queue_compression_stats.dig('encode', 'goal')).to eq(settings_overrides['queue.compression'])
            expect(queue_compression_stats.dig('encode', 'ratio', 'lifetime')).to be <= 1
            expect(queue_compression_stats.dig('encode', 'spend', 'lifetime')).not_to be_nil
          end
        else
          expect(queue_stats["type"]).to eq("memory")
        end
      end
    end

    context "when pipeline.batch.metrics.sampling_mode is set to 'full'" do
      let(:settings_overrides) do
        super().merge({'pipeline.batch.metrics.sampling_mode' => 'full'})
      end

      it "can retrieve batch stats" do
        logstash_service.start_with_stdin
        logstash_service.wait_for_logstash

        number_of_events.times {
          logstash_service.write_to_stdin("Testing flow metrics")
          sleep(1)
        }

        Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
          # node_stats can fail if the stats subsystem isn't ready
          result = logstash_service.monitoring_api.node_stats rescue nil
          expect(result).not_to be_nil
          # we use fetch here since we want failed fetches to raise an exception
          # and trigger the retry block
          batch_stats = result.fetch("pipelines").fetch(pipeline_id).fetch("batch")
          expect(batch_stats).not_to be_nil

          expect(batch_stats["event_count"]).not_to be_nil
          expect(batch_stats["event_count"]["average"]).not_to be_nil
          expect(batch_stats["event_count"]["average"]["lifetime"]).not_to be_nil
          expect(batch_stats["event_count"]["average"]["lifetime"]).to be_a_kind_of(Numeric)
          expect(batch_stats["event_count"]["average"]["lifetime"]).to be > 0

          expect(batch_stats["event_count"]["current"]).not_to be_nil
          expect(batch_stats["event_count"]["current"]).to be >= 0

          expect(batch_stats["byte_size"]).not_to be_nil
          expect(batch_stats["byte_size"]["average"]).not_to be_nil
          expect(batch_stats["byte_size"]["average"]["lifetime"]).not_to be_nil
          expect(batch_stats["byte_size"]["average"]["lifetime"]).to be_a_kind_of(Numeric)
          expect(batch_stats["byte_size"]["average"]["lifetime"]).to be > 0

          expect(batch_stats["byte_size"]["current"]).not_to be_nil
          expect(batch_stats["byte_size"]["current"]).to be >= 0
        end
      end
    end

    context "when pipeline.batch.metrics.sampling_mode is set to 'disabled'" do
      let(:settings_overrides) do
        super().merge({'pipeline.batch.metrics.sampling_mode' => 'disabled'})
      end

      it "no batch stats metrics are available" do
        logstash_service.start_with_stdin
        logstash_service.wait_for_logstash

        number_of_events.times {
          logstash_service.write_to_stdin("Testing flow metrics")
          sleep(1)
        }

        Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
          # node_stats can fail if the stats subsystem isn't ready
          result = logstash_service.monitoring_api.node_stats rescue nil
          expect(result).not_to be_nil
          # we use fetch here since we want failed fetches to raise an exception
          # and trigger the retry block
          pipeline_stats = result.fetch("pipelines").fetch(pipeline_id)
          expect(pipeline_stats).not_to include("batch")
        end
      end
    end

    it "retrieves the pipeline flow statuses" do
      logstash_service = @fixture.get_service("logstash")
      logstash_service.start_with_stdin
      logstash_service.wait_for_logstash
      number_of_events.times {
        logstash_service.write_to_stdin("Testing flow metrics")
        sleep(1)
      }

      Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
        # node_stats can fail if the stats subsystem isn't ready
        result = logstash_service.monitoring_api.node_stats rescue nil
        expect(result).not_to be_nil
        # we use fetch here since we want failed fetches to raise an exception
        # and trigger the retry block
        expect(result).to include('pipelines' => hash_including(pipeline_id => hash_including('flow')))
        flow_status = result.dig("pipelines", pipeline_id, "flow")
        expect(flow_status).to_not be_nil
        expect(flow_status).to include(
                                 # due to three-decimal-place rounding, it is easy for our worker_concurrency and queue_backpressure
                                 # to be zero, so we are just looking for these to be _populated_
                                 'worker_concurrency' => hash_including('current' => a_value >= 0, 'lifetime' => a_value >= 0),
                                 'worker_utilization' => hash_including('current' => a_value >= 0, 'lifetime' => a_value >= 0),
                                 'queue_backpressure' => hash_including('current' => a_value >= 0, 'lifetime' => a_value >= 0),
                                 # depending on flow capture interval, our current rate can easily be zero, but our lifetime rates
                                 # should be non-zero so long as pipeline uptime is less than ~10 minutes.
                                 'input_throughput'   => hash_including('current' => a_value >= 0, 'lifetime' => a_value >  0),
                                 'filter_throughput'  => hash_including('current' => a_value >= 0, 'lifetime' => a_value >  0),
                                 'output_throughput'  => hash_including('current' => a_value >= 0, 'lifetime' => a_value >  0)
                               )
        if logstash_service.settings.feature_flag == "persistent_queues"
          expect(flow_status).to include(
                                   'queue_persisted_growth_bytes'  => hash_including('current' => a_kind_of(Numeric), 'lifetime' => a_kind_of(Numeric)),
                                   'queue_persisted_growth_events' => hash_including('current' => a_kind_of(Numeric), 'lifetime' => a_kind_of(Numeric))
                                 )
        else
          expect(flow_status).to_not include('queue_persisted_growth_bytes')
          expect(flow_status).to_not include('queue_persisted_growth_events')
        end
      end
    end

    shared_examples "plugin-level flow metrics" do
      let(:settings_overrides) do
        super().merge({'config.string' => config_string})
      end

      let(:config_string) do
        <<~EOPIPELINE
          input { stdin { id => '#{plugin_id_input}' } }
          filter { mutate { id => '#{plugin_id_filter}' add_tag => 'integration test adding tag' } }
          output { stdout { id => '#{plugin_id_output}' } }
        EOPIPELINE
      end

      it "retrieves plugin level flow metrics" do
        logstash_service.spawn_logstash
        logstash_service.wait_for_logstash
        number_of_events.times {
          logstash_service.write_to_stdin("Testing plugin-level flow metrics")
          sleep(1)
        }

        Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
          # node_stats can fail if the stats subsystem isn't ready
          result = logstash_service.monitoring_api.node_stats rescue nil
          # if the result is nil, we probably aren't ready yet
          # our assertion failure will cause Stud to retry
          expect(result).not_to be_nil

          expect(result).to include('pipelines' => hash_including(pipeline_id => hash_including('plugins' => hash_including('inputs', 'filters', 'outputs'))))

          input_plugins = result.dig("pipelines", pipeline_id, "plugins", "inputs")
          filter_plugins = result.dig("pipelines", pipeline_id, "plugins", "filters")
          output_plugins = result.dig("pipelines", pipeline_id, "plugins", "outputs")
          expect(input_plugins[0]).to_not be_nil # not ready...

          expect(input_plugins).to include(a_hash_including(
                                             'id' => plugin_id_input,
                                             'flow' => a_hash_including(
                                               'throughput' => hash_including('current' => a_value >= 0, 'lifetime' => a_value > 0)
                                             )
                                           ))

          expect(filter_plugins).to include(a_hash_including(
                                              'id' => plugin_id_filter,
                                              'flow' => a_hash_including(
                                                'worker_utilization' => hash_including('current' => a_value >= 0, 'lifetime' => a_value >= 0),
                                                'worker_millis_per_event' => hash_including('current' => a_value >= 0, 'lifetime' => a_value >= 0),
                                                )
                                            ))

          expect(output_plugins).to include(a_hash_including(
                                              'id' => plugin_id_output,
                                              'flow' => a_hash_including(
                                                'worker_utilization' => hash_including('current' => a_value >= 0, 'lifetime' => a_value >= 0),
                                                'worker_millis_per_event' => hash_including('current' => a_value >= 0, 'lifetime' => a_value >= 0),
                                                )
                                            ))
        end
      end
    end

    context "with lower-ASCII plugin id's" do
      let(:plugin_id_input) { "standard-input" }
      let(:plugin_id_filter) { "Mutations" }
      let(:plugin_id_output) { "StandardOutput" }
      include_examples "plugin-level flow metrics"
    end

    context "with unicode plugin id's" do
      let(:plugin_id_input) { "입력" }
      let(:plugin_id_filter) { "変じる" }
      let(:plugin_id_output) { "le-résultat" }
      include_examples "plugin-level flow metrics"
    end

  end

  context "with lower-ASCII pipeline id" do
    let(:pipeline_id) { "main" }
    include_examples "pipeline metrics"
  end

  context "with unicode pipeline id" do
    before(:each) do
      if @fixture.settings.feature_flag == "persistent_queues"
        skip('behaviour for unicode pipeline ids is unspecified when PQ is enabled')
        # NOTE: pipeline ids are used verbatim as a part of the queue path, so the subset
        #       of unicode characters that are supported depend on the OS and Filesystem.
        #       The pipeline will fail to start, rendering these monitoring specs useless.
      end
    end
    let(:pipeline_id) { "변환-verändern-変ずる" }
    include_examples "pipeline metrics"
  end

  it "can configure logging" do
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # monitoring api can fail if the subsystem isn't ready
      result = logstash_service.monitoring_api.logging_get rescue nil
      expect(result).to_not be_nil
      expect(result).to include("loggers" => an_object_having_attributes(:size => a_value > 0))
    end

    #default
    logging_get_assert logstash_service, ["WARN", "INFO"], "TRACE",
                       skip: 'logstash.licensechecker.licensereader' #custom (ERROR) level to start with

    #root logger - does not apply to logger.slowlog
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger." => "WARN"})
    logging_get_assert logstash_service, "WARN", "TRACE", skip: 'logstash.licensechecker.licensereader'
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger." => "INFO"})
    logging_get_assert logstash_service, ["WARN", "INFO"], "TRACE", skip: 'logstash.licensechecker.licensereader'

    #package logger
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash.agent" => "DEBUG"})
    expect(logstash_service.monitoring_api.logging_get["loggers"]["logstash.agent"]).to eq ("DEBUG")
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash.agent" => "INFO"})
    expect(logstash_service.monitoring_api.logging_get["loggers"]["logstash.agent"]).to eq ("INFO")

    #parent package loggers
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash" => "ERROR"})
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.slowlog" => "ERROR"})

    #deprecation package loggers
    logging_put_assert logstash_service.monitoring_api.logging_put({"logger.deprecation" => "ERROR"})

    result = logstash_service.monitoring_api.logging_get
    result["loggers"].each do |k, v|
      next if k.eql?("logstash.agent")
      next if k.eql?("logstash.licensechecker.licensereader")
      #since we explicitly set the logstash.agent logger above, the logger.logstash parent logger will not take precedence
      if k.start_with?("logstash") || k.start_with?("slowlog") || k.start_with?("deprecation")
        expect(v).to eq("ERROR")
      end
    end

    # all log levels should be reset to original values
    logging_put_assert logstash_service.monitoring_api.logging_reset
    logging_get_assert logstash_service, ["WARN", "INFO"], "TRACE", skip: 'logstash.licensechecker.licensereader'
  end


  private

  def logging_get_assert(logstash_service, logstash_level, slowlog_level, skip: '')
    result = logstash_service.monitoring_api.logging_get
    result["loggers"].each do |k, v|
      next if !k.empty? && k.eql?(skip)
      if k.start_with? "logstash", "org.logstash" #logstash is the ruby namespace, and org.logstash for java
        if logstash_level.is_a?(Array)
          if logstash_level.size == 1
            expect(v).to eq(logstash_level[0]), "logstash logger '#{k}' has logging level: #{v} expected: #{logstash_level[0]}"
          else
            expect(logstash_level).to include(v), "logstash logger '#{k}' has logging level: #{v} expected to be one of: #{logstash_level}"
          end
        else
          expect(v).to eq(logstash_level), "logstash logger '#{k}' has logging level: #{v} expected: #{logstash_level}"
        end
      elsif k.start_with? "slowlog"
        expect(v).to eq(slowlog_level), "slowlog logger '#{k}' has logging level: #{v} expected: #{slowlog_level}"
      end
    end
  end

  def logging_put_assert(result)
    expect(result['acknowledged']).to be(true), "result not acknowledged, got: #{result.inspect}"
  end
end
