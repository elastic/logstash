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

require "logstash/util/loggable"
require "logstash/instrument/periodic_poller/os"
require "set"

java_import 'org.logstash.instrument.metrics.otel.OTelMetricsService'
java_import 'io.opentelemetry.api.common.Attributes'
java_import 'io.opentelemetry.api.common.AttributeKey'

module LogStash module Instrument module PeriodicPoller
  # Exports Logstash metrics to an OpenTelemetry-compatible backend via OTLP.
  #
  # This class extends Base to use the periodic polling mechanism for collecting
  # metrics into the metric store. The OTel SDK callbacks then read from the
  # refreshed snapshot during export.
  #
  # Configuration in logstash.yml:
  #   otel.metrics.enabled: true
  #   otel.metrics.endpoint: "http://localhost:4317"
  #   otel.metrics.interval: 10
  #   otel.metrics.protocol: "grpc"
  #   otel.resource.attributes: "environment=production,cluster=us-west"
  #
  class OTel < Base

    def initialize(metric, agent, settings)
      @agent = agent
      @settings = settings
      @metric_store = agent.metric.collector

      # Initialize the OTel service - SDK handles its own export timing
      @otel_service = OTelMetricsService.new(
        settings.get("otel.metrics.endpoint"),
        agent.id,
        agent.name,
        settings.get("otel.metrics.interval"),
        settings.get("otel.metrics.protocol"),
        settings.get("otel.resource.attributes")
      )

      # Call Base initializer - sets up @metric and configures the TimerTask
      super(metric, :polling_interval => settings.get("otel.metrics.interval"))

      # Take initial snapshot
      @snapshot = @metric_store.snapshot_metric

      # Track which pipelines and plugins have been registered to avoid duplicates
      @registered_pipelines = Set.new
      @registered_plugins = Set.new

      # Register global and cgroup metrics immediately (not pipeline-specific)
      register_global_metrics
      register_cgroup_metrics

      logger.info("OpenTelemetry metrics poller initialized",
                  :endpoint => settings.get("otel.metrics.endpoint"),
                  :interval => settings.get("otel.metrics.interval"))
    end

    def stop
      logger.info("Stopping OpenTelemetry metrics poller")
      super
      @otel_service.flush
      @otel_service.shutdown
    end

    def collect
      # Register metrics for any new pipelines that have started since initialization
      register_new_pipeline_metrics

      # Register metrics for any new plugins (they appear after processing first event)
      register_new_plugin_metrics

      collect_cgroup_metrics
      collect_pipeline_metrics
      collect_dlq_metrics
      @agent.capture_flow_metrics
      # Refresh snapshot after collecting metrics so OTel callbacks read fresh data
      @snapshot = @metric_store.snapshot_metric
    end

    def register_new_plugin_metrics
      @agent.pipelines_registry.running_pipelines.each do |pipeline_id, _pipeline|
        register_plugin_metrics_for(pipeline_id)
      end
    end

    def register_new_pipeline_metrics
      @agent.pipelines_registry.running_pipelines.each do |pipeline_id, _pipeline|
        next if @registered_pipelines.include?(pipeline_id)

        logger.debug("Registering OTel metrics for pipeline", :pipeline_id => pipeline_id)
        register_pipeline_counters_for(pipeline_id)
        register_pipeline_gauges_for(pipeline_id)
        register_dlq_metrics_for(pipeline_id)
        @registered_pipelines.add(pipeline_id)
      end
    end

    private

    def collect_cgroup_metrics
      Os.collect_cgroup(@metric)
    end

    def collect_dlq_metrics
      pipelines = @agent.running_user_defined_pipelines
      pipelines.each do |_, pipeline|
        unless pipeline.nil?
          pipeline.collect_dlq_stats
        end
      end
    end

    def collect_pipeline_metrics
      pipelines = @agent.running_user_defined_pipelines
      pipelines.each do |_, pipeline|
        unless pipeline.nil?
          pipeline.collect_stats
        end
      end
    end

    # Register Dead Letter Queue metrics for a specific pipeline
    def register_dlq_metrics_for(pipeline_id)
      attrs = create_pipeline_attributes(pipeline_id)

      register_gauge(
        "logstash.pipeline.dlq.queue_size",
        "Current dead letter queue size",
        "By",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :dead_letter_queue, :queue_size_in_bytes)
      end

      register_gauge(
        "logstash.pipeline.dlq.max_queue_size",
        "Maximum dead letter queue size limit",
        "By",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :dead_letter_queue, :max_queue_size_in_bytes)
      end

      register_gauge(
        "logstash.pipeline.dlq.dropped_events",
        "Events dropped when DLQ is full",
        "{event}",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :dead_letter_queue, :dropped_events)
      end

      register_gauge(
        "logstash.pipeline.dlq.expired_events",
        "Events expired and removed from DLQ",
        "{event}",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :dead_letter_queue, :expired_events)
      end
    end

    # Register cgroup metrics
    def register_cgroup_metrics
      # Reports the total CPU time consumed by all tasks in this cgroup (including tasks lower in the hierarchy)
      # - observable counter (monotonically increasing)
      register_observable_counter("logstash.os.cgroup.cpuacct.usage", "Total CPU time consumed", "ns") do
        get_metric_value(:os, :cgroup, :cpuacct, :usage_nanos)
      end

      # A period of time in microseconds for how regularly a cgroup's access to CPU resources should be
      # reallocated - gauges (can change at runtime)
      register_gauge("logstash.os.cgroup.cpu.cfs_period", "CFS scheduling period", "us") do
        get_metric_value(:os, :cgroup, :cpu, :cfs_period_micros)
      end

      # Total amount of time in microseconds for which all tasks in a cgroup can run during one period
      # - gauges (can change at runtime)
      register_gauge("logstash.os.cgroup.cpu.cfs_quota", "CFS scheduling quota", "us") do
        get_metric_value(:os, :cgroup, :cpu, :cfs_quota_micros)
      end

      # Number of period intervals that have elapsed - observable counters (monotonically increasing)
      register_observable_counter("logstash.os.cgroup.cpu.stat.elapsed_periods", "Number of elapsed CFS periods", "{period}") do
        get_metric_value(:os, :cgroup, :cpu, :stat, :number_of_elapsed_periods)
      end

      # Number of times the tasks in this cgroup were throttled - observable counters (monotonically increasing)
      register_observable_counter("logstash.os.cgroup.cpu.stat.nr_times_throttled", "Number of times throttled", "{occurrence}") do
        get_metric_value(:os, :cgroup, :cpu, :stat, :number_of_times_throttled)
      end

      # Total time in nanoseconds for which tasks in this cgroup were throttled - observable counters (monotonically increasing)
      register_observable_counter("logstash.os.cgroup.cpu.stat.time_throttled", "Total time throttled", "ns") do
        get_metric_value(:os, :cgroup, :cpu, :stat, :time_throttled_nanos)
      end
    end

    def register_pipeline_gauges_for(pipeline_id)
      attrs = create_pipeline_attributes(pipeline_id)

      register_gauge(
        "logstash.pipeline.queue.events",
        "Events in pipeline queue",
        "{event}",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :queue, :events)
      end

      # Persistent queue capacity metrics
      register_gauge(
        "logstash.pipeline.queue.capacity.page_capacity",
        "Size of each queue page",
        "By",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :queue, :capacity, :page_capacity_in_bytes)
      end

      register_gauge(
        "logstash.pipeline.queue.capacity.max_size",
        "Maximum queue size limit",
        "By",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :queue, :capacity, :max_queue_size_in_bytes)
      end

      register_gauge(
        "logstash.pipeline.queue.capacity.max_unread_events",
        "Maximum unread events allowed in queue",
        "{event}",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :queue, :capacity, :max_unread_events)
      end

      register_gauge(
        "logstash.pipeline.queue.capacity.size",
        "Current persisted queue size",
        "By",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :queue, :capacity, :queue_size_in_bytes)
      end

      # Persistent queue data/storage metrics
      register_gauge(
        "logstash.pipeline.queue.data.free_space",
        "Free disk space where queue is stored",
        "By",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :queue, :data, :free_space_in_bytes)
      end
    end

    # Register observable counters - SDK computes deltas from cumulative values
    def register_global_metrics
      # Global event counters
      register_observable_counter("logstash.events.in", "Total events received", "{event}") do
        get_metric_value(:stats, :events, :in)
      end

      register_observable_counter("logstash.events.out", "Total events output", "{event}") do
        get_metric_value(:stats, :events, :out)
      end

      register_observable_counter("logstash.events.filtered", "Total events filtered", "{event}") do
        get_metric_value(:stats, :events, :filtered)
      end

      # Global queue gauge (total across all pipelines)
      register_gauge("logstash.queue.events", "Total events in queues", "{event}") do
        get_total_queue_events
      end
    end

    def register_pipeline_counters_for(pipeline_id)
      attrs = create_pipeline_attributes(pipeline_id)

      register_observable_counter(
        "logstash.pipeline.events.in",
        "Events received by pipeline",
        "{event}",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :events, :in)
      end

      register_observable_counter(
        "logstash.pipeline.events.out",
        "Events output by pipeline",
        "{event}",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :events, :out)
      end

      register_observable_counter(
        "logstash.pipeline.events.filtered",
        "Events filtered by pipeline",
        "{event}",
        attrs
      ) do
        get_pipeline_metric_value(pipeline_id, :events, :filtered)
      end
    end

    def register_gauge(name, description, unit, attributes = Attributes.empty, &block)
      supplier = -> {
        begin
          value = block.call
          value.nil? ? nil : value.to_java(:long)
        rescue => e
          logger.debug("Error getting gauge value for #{name}", :error => e.message)
          nil
        end
      }
      @otel_service.registerGauge(name, description, unit, supplier, attributes)
    end

    def register_observable_counter(name, description, unit, attributes = Attributes.empty, &block)
      supplier = -> {
        begin
          value = block.call
          value.nil? ? nil : value.to_java(:long)
        rescue => e
          logger.debug("Error getting observable counter value for #{name}", :error => e.message)
          nil
        end
      }

      @otel_service.registerObservableCounter(name, description, unit, supplier, attributes)
    end

    # Helper to get metric values from the store
    def get_metric_value(*path)
      store = @snapshot.metric_store

      result = store.get_shallow(*path)
      result.is_a?(Hash) ? nil : result&.value
    rescue LogStash::Instrument::MetricStore::MetricNotFound
      nil
    end

    def get_pipeline_metric_value(pipeline_id, *path)
      full_path = [:stats, :pipelines, pipeline_id.to_sym] + path
      get_metric_value(*full_path)
    end

    def get_total_queue_events
      total = 0
      @agent.pipelines_registry.running_pipelines.each do |pipeline_id, pipeline|
        next if pipeline.system?
        queue_events = get_pipeline_metric_value(pipeline_id, :queue, :events)
        total += queue_events if queue_events
      end
      total
    end

    def create_pipeline_attributes(pipeline_id)
      Attributes.of(
        AttributeKey.stringKey("pipeline.id"), pipeline_id.to_s
      )
    end

    def create_plugin_attributes(pipeline_id, plugin_type, plugin_id)
      Attributes.of(
        AttributeKey.stringKey("pipeline.id"), pipeline_id.to_s,
        AttributeKey.stringKey("plugin.type"), plugin_type.to_s,
        AttributeKey.stringKey("plugin.id"), plugin_id.to_s
      )
    end

    # Register plugin metrics for a specific pipeline
    # Called on each collect to discover newly available plugins
    def register_plugin_metrics_for(pipeline_id)
      [:filters, :outputs, :inputs].each do |plugin_type|
        plugin_ids = get_plugin_ids(pipeline_id, plugin_type)
        plugin_ids.each do |plugin_id|
          plugin_key = "#{pipeline_id}:#{plugin_type}:#{plugin_id}"
          next if @registered_plugins.include?(plugin_key)

          logger.debug("Registering OTel metrics for plugin",
                       :pipeline_id => pipeline_id,
                       :plugin_type => plugin_type,
                       :plugin_id => plugin_id)
          register_plugin_counters_for(pipeline_id, plugin_type, plugin_id)
          @registered_plugins.add(plugin_key)
        end
      end
    end

    def get_plugin_ids(pipeline_id, plugin_type)
      begin
        store = @snapshot.metric_store
        plugins_hash = store.get_shallow(:stats, :pipelines, pipeline_id.to_sym, :plugins, plugin_type)
        return [] unless plugins_hash.is_a?(Hash)
        plugins_hash.keys
      rescue LogStash::Instrument::MetricStore::MetricNotFound
        []
      end
    end

    def register_plugin_counters_for(pipeline_id, plugin_type, plugin_id)
      attrs = create_plugin_attributes(pipeline_id, plugin_type, plugin_id)

      register_observable_counter(
        "logstash.plugin.events.in",
        "Events received by plugin",
        "{event}",
        attrs
      ) do
        get_plugin_metric_value(pipeline_id, plugin_type, plugin_id, :events, :in)
      end

      register_observable_counter(
        "logstash.plugin.events.out",
        "Events output by plugin",
        "{event}",
        attrs
      ) do
        get_plugin_metric_value(pipeline_id, plugin_type, plugin_id, :events, :out)
      end

      register_observable_counter(
        "logstash.plugin.events.duration",
        "Time spent processing events",
        "ms",
        attrs
      ) do
        get_plugin_metric_value(pipeline_id, plugin_type, plugin_id, :events, :duration_in_millis)
      end
    end

    def get_plugin_metric_value(pipeline_id, plugin_type, plugin_id, *path)
      full_path = [:stats, :pipelines, pipeline_id.to_sym, :plugins, plugin_type, plugin_id.to_sym] + path
      get_metric_value(*full_path)
    end
  end
end; end; end