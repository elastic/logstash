# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/event"
require "logstash/inputs/base"
require "logstash/instrument/collector"
require 'license_checker/licensed'
require 'helpers/elasticsearch_options'
require "concurrent"
require "thread"

module LogStash module Inputs
  # The Metrics input recieves periodic metric data snapshot from Logstash core.
  # This input is responsible for registring itself to the collector.
  # The collector class will periodically emits new snapshot of the system, JVM and other metric data.
  # This input further transform it into a `Logstash::Event`, which can be consumed by the shipper and
  # shipped to Elasticsearch
  class Metrics < LogStash::Inputs::Base
    include LogStash::LicenseChecker::Licensed, LogStash::Helpers::ElasticsearchOptions

    require "monitoring/inputs/metrics/state_event_factory"
    require "monitoring/inputs/metrics/stats_event_factory"
    
    @pipelines_mutex = Mutex.new
    @pipelines = {}

    VALID_LICENSES = %w(basic trial standard gold platinum)
    FEATURE = 'monitoring'

    require "monitoring/inputs/timer_task_logger"
    
    attr_reader :queue, :agent
  
    config_name "metrics"

    # Polling frequency in seconds on the metric store
    config :collection_interval, :type => :integer, :default => 10

    # Maximum time in seconds a polling iteration of the metric store can take before it dies
    # When it dies, the snapshot will wait the `collection_interval` before doing another snapshot.
    config :collection_timeout_interval, :type => :integer, :default => 10 * 60

    # Collect per-plugin / queue / other component stats
    config :extended_performance_collection, :type => :boolean, :default => true

    # Serialize and store the logstash config into logstash-states
    config :config_collection, :type => :boolean, :default => true

    def register
      @global_stats = fetch_global_stats
      @agent = nil
      @settings = LogStash::SETTINGS.clone
      @last_updated_pipeline_hashes = []
      @es_options = es_options_from_settings_or_modules(FEATURE, @settings)
      setup_license_checker(FEATURE)
      configure_snapshot_poller
    end

    def pipeline_started(agent, pipeline)
      @agent = agent

      with_license_check do
        update_pipeline_state(pipeline)
      end
    end

    def configure_snapshot_poller
      @timer_task = Concurrent::TimerTask.new({
        :execution_interval => @collection_interval,
        :timeout_interval => @collection_timeout_interval
      }) do
        update(metric.collector.snapshot_metric)
      end

      @timer_task.add_observer(TimerTaskLogger.new)
    end

      def run(arg_queue)
        @logger.debug("Metric: input started")
        @queue = arg_queue

        # This must be invoked here because we need a queue to store the data
        LogStash::PLUGIN_REGISTRY.hooks.register_hooks(LogStash::Agent, self)

        exec_timer_task
        sleep_till_stop
      end

    def exec_timer_task
      @timer_task.execute
    end

    def sleep_till_stop
      # Keep this plugin thread alive,
      # until we shutdown the metric pipeline
      sleep(1) while !stop?
    end

    def stop
      @logger.debug("Metrics input: stopped")
      @timer_task.shutdown if @timer_task
    end

    def update(snapshot)
      with_license_check do
        update_stats(snapshot)
        update_states
      end
    end

    def update_stats(snapshot)
      @logger.debug("Metrics input: received a new snapshot", :created_at => snapshot.created_at, :snapshot => snapshot) if @logger.debug?

      begin
        event = StatsEventFactory.new(@global_stats, snapshot).make(agent, @extended_performance_collection)
      rescue => e
        if @logger.debug?
          @logger.error("Failed to create monitoring event", :message => e.message, :error => e.class.name, :backtrace => e.backtrace)
        else
          @logger.error("Failed to create monitoring event", :message => e.message, :error => e.class.name)
        end

        return
      end

      remove_reserved_fields(event)

      # The back pressure is handled in the collector's
      # scheduled task (running into his own thread) if something append to one of the listener it will
      # will timeout. In a sane pipeline, with a low traffic of events it shouldn't be a problems.
      emit_event(event)
    end

    def update_states
      return unless @agent

      # Update once every 10m
      time_for_update = @last_states_update.nil? || @last_states_update < (Time.now - 60*10)

      pipeline_hashes = []
      agent.pipelines.each do |pipeline_id, pipeline|
        if time_for_update || !@last_updated_pipeline_hashes.include?(pipeline.hash)
          update_pipeline_state(pipeline)
        end
        pipeline_hashes << pipeline.hash
      end

      @last_updated_pipeline_hashes = pipeline_hashes
      @last_states_update ||= Time.now
    end

    def update_pipeline_state(pipeline)
      return if pipeline.system?
      if @config_collection
        emit_event(state_event_for(pipeline))
      end
    end

    def state_event_for(pipeline)
      StateEventFactory.new(pipeline).make()
    end

    def emit_event(event)
      queue << event
    end

    def populate_license_state(xpack_info)
      if !xpack_info.installed?
        {
            :state => :error,
            :log_level => :error,
            :log_message => "X-Pack is installed on Logstash but not on Elasticsearch. Please install X-Pack on Elasticsearch to use the monitoring feature. Other features may be available."
        }
      elsif !xpack_info.license_available?
        {
            :state => :error,
            :log_level => :error,
            :log_message => 'Monitoring is not available: License information is currently unavailable. Please make sure you have added your production elasticsearch connection info in the xpack.monitoring.elasticsearch settings.'
        }
      elsif !xpack_info.license_one_of?(VALID_LICENSES)
        {
            :state => :error,
            :log_level => :error,
            :log_message => "Monitoring is not available: #{xpack_info.license_type} is not a valid license for this feature."
        }
      elsif !xpack_info.license_active?
        {
            :state => :ok,
            :log_level => :warn,
            :log_message => 'Monitoring requires a valid license. You can continue to monitor Logstash, but please contact your administrator to update your license'
        }
      else
        unless xpack_info.feature_enabled?(FEATURE)
          logger.warn('Monitoring installed and enabled in Logstash, but not enabled in Elasticsearch')
        end

        { :state => :ok, :log_level => :info, :log_message => 'Monitoring License OK' }
      end
    end

    private
    def remove_reserved_fields(event)
      event.remove("@timestamp")
      event.remove("@version")
    end

    def fetch_global_stats
      {
        "uuid" => LogStash::SETTINGS.get("node.uuid"),
        "name" => LogStash::SETTINGS.get("node.name"),
        "host" => Socket.gethostname,
        "http_address" => nil,
        "ephemeral_id" => nil,
        "version" => ::LOGSTASH_VERSION,
        "snapshot" => ::BUILD_INFO["build_snapshot"],
        "status" => "green",
        "pipeline" => {
          "workers" => LogStash::SETTINGS.get("pipeline.workers"),
          "batch_size" => LogStash::SETTINGS.get("pipeline.batch.size"),
        }
      }
    end
  end
end; end
