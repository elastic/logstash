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

      define_initial_metrics_values
    end

    def get_new_batch
      @write_client.get_new_batch
    end

    def push(event)
      record_metric { @write_client.push(event) }
    end
    alias_method(:<<, :push)

    def push_batch(batch)
      record_metric(batch.size) { @write_client.push_batch(batch) }
    end

    private
    def record_metric(size = 1)
      @events_metrics.increment(:in, size)
      @pipeline_metrics.increment(:in, size)
      @plugin_events_metrics.increment(:out, size)

      clock = @events_metrics.time(:queue_push_duration_in_millis)

      result = yield

      # Reuse the same values for all the endpoints to make sure we don't have skew in times.
      execution_time = clock.stop

      @pipeline_metrics.report_time(:queue_push_duration_in_millis, execution_time)
      @plugin_events_metrics.report_time(:queue_push_duration_in_millis, execution_time)

      result
    end

    def define_initial_metrics_values
      @events_metrics.increment(:in, 0)
      @pipeline_metrics.increment(:in, 0)
      @plugin_events_metrics.increment(:out, 0)

      @events_metrics.report_time(:queue_push_duration_in_millis, 0)
      @pipeline_metrics.report_time(:queue_push_duration_in_millis, 0)
      @plugin_events_metrics.report_time(:queue_push_duration_in_millis, 0)
    end
  end
end end
