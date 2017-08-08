# encoding: utf-8
module LogStash module Instrument
  class WrappedWriteClient
    def initialize(write_client, pipeline, metric, plugin)
      @write_client = write_client

      pipeline_id = pipeline.pipeline_id.to_s.to_sym
      plugin_type = "#{plugin.class.plugin_type}s".to_sym

      @events_metrics = metric.namespace([:stats, :events])
      @pipeline_metrics = metric.namespace([:stats, :pipelines, pipeline_id, :events])
      @plugin_events_metrics = metric.namespace([:stats, :pipelines, pipeline_id, :plugins, plugin_type, plugin.id.to_sym, :events])
      @events_metrics_counter = @events_metrics.counter(:in)
      @pipeline_metrics_counter = @pipeline_metrics.counter(:in)
      @plugin_events_metrics_counter = @plugin_events_metrics.counter(:out)
      define_initial_metrics_values
    end

    def get_new_batch
      @write_client.get_new_batch
    end

    def push(event)
      increment_counters(1)
      start_time = java.lang.System.current_time_millis
      result = @write_client.push(event)
      report_execution_time(start_time)
      result
    end

    alias_method(:<<, :push)

    def push_batch(batch)
      increment_counters(batch.size)
      start_time = java.lang.System.current_time_millis
      result = @write_client.push_batch(batch)
      report_execution_time(start_time)
      result
    end

    private

    def increment_counters(size)
      @events_metrics_counter.increment(size)
      @pipeline_metrics_counter.increment(size)
      @plugin_events_metrics_counter.increment(size)
    end

    def report_execution_time(start_time)
      execution_time = java.lang.System.current_time_millis - start_time
      @events_metrics.report_time(:queue_push_duration_in_millis, execution_time)
      # Reuse the same values for all the endpoints to make sure we don't have skew in times.
      @pipeline_metrics.report_time(:queue_push_duration_in_millis, execution_time)
      @plugin_events_metrics.report_time(:queue_push_duration_in_millis, execution_time)
    end

    def define_initial_metrics_values
      @events_metrics_counter.increment(0)
      @pipeline_metrics_counter.increment(0)
      @plugin_events_metrics_counter.increment(0)

      @events_metrics.report_time(:queue_push_duration_in_millis, 0)
      @pipeline_metrics.report_time(:queue_push_duration_in_millis, 0)
      @plugin_events_metrics.report_time(:queue_push_duration_in_millis, 0)
    end
  end
end end
