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

java_import 'org.logstash.instrument.metrics.otel.OtelMetricsService'
java_import 'io.opentelemetry.api.common.Attributes'
java_import 'io.opentelemetry.api.common.AttributeKey'

module LogStash module Instrument module PeriodicPoller
  # Exports Logstash metrics to an OpenTelemetry-compatible backend via OTLP.
  #
  # This class does NOT extend Base because:
  # - All metrics use observable callbacks that the OTel SDK invokes at export time
  # - The OTel SDK handles its own export timing via PeriodicMetricReader
  # - No periodic polling/TimerTask is needed from the Ruby side
  #
  # Configuration in logstash.yml:
  #   otel.metrics.enabled: true
  #   otel.metrics.endpoint: "http://localhost:4317"
  #   otel.metrics.interval: 10
  #   otel.metrics.protocol: "grpc"
  #   otel.resource.attributes: "environment=production,cluster=us-west"
  #
  class Otel
    include LogStash::Util::Loggable

    def initialize(metric, agent, settings)
      @agent = agent
      @settings = settings
      @metric_store = agent.metric.collector

      # Initialize the OTel service - SDK handles its own export timing
      @otel_service = OtelMetricsService.new(
        settings.get("otel.metrics.endpoint"),
        agent.id,
        agent.name,
        settings.get("otel.metrics.interval"),
        settings.get("otel.metrics.protocol"),
        settings.get("otel.resource.attributes")
      )

      # Register all metrics with callbacks - SDK invokes them at export time
      register_global_metrics
      register_pipeline_metrics
      register_cgroup_metrics

      logger.info("OpenTelemetry metrics poller initialized",
                  :endpoint => settings.get("otel.metrics.endpoint"),
                  :interval => settings.get("otel.metrics.interval"))
    end

    def start
      # No-op: OTel SDK handles export timing via PeriodicMetricReader
      logger.debug("OpenTelemetry metrics exporter active")
    end

    def stop
      logger.info("Stopping OpenTelemetry metrics poller")
      @otel_service.flush
      @otel_service.shutdown
    end

    private

    # Register Pipeline metrics from pipeline.rb
    def register_pipeline_metrics
      # Queue gauge (total across all pipelines)
      register_gauge("logstash.queue.events", "Total events in queues", "{event}") do
        get_total_queue_events
      end

      # Per-pipeline metrics
      register_pipeline_counters
      register_pipeline_gauges 
      register_dlq_metrics
    end

    # Register Dead Letter Queue metrics
    def register_dlq_metrics
      @agent.pipelines_registry.running_pipelines.each do |pipeline_id, _pipeline|
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

    def register_pipeline_gauges
      # These will be registered for each running pipeline
      # TODO: Handle dynamic pipeline add/remove
      @agent.pipelines_registry.running_pipelines.each do |pipeline_id, _pipeline|
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
    end

    def register_pipeline_counters
      @agent.pipelines_registry.running_pipelines.each do |pipeline_id, _pipeline|
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
      snapshot = @metric_store.snapshot_metric
      store = snapshot.metric_store

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
  end
end; end; end