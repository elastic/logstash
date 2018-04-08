# encoding: utf-8
#
module LogStash
  class JavaFilterDelegator
    include org.logstash.config.ir.compiler.RubyIntegration::Filter
    extend Forwardable
    DELEGATED_METHODS = [
      :register,
      :close,
      :threadsafe?,
      :do_close,
      :do_stop,
      :periodic_flush,
      :reloadable?
    ]
    def_delegators :@filter, *DELEGATED_METHODS

    attr_reader :id

    def initialize(filter, id)
      @klass = filter.class
      @id = id
      @filter = filter

      # Scope the metrics to the plugin
      namespaced_metric = filter.metric
      @metric_events = namespaced_metric.namespace(:events)
      @metric_events_in = @metric_events.counter(:in)
      @metric_events_out = @metric_events.counter(:out)
      @metric_events_time = @metric_events.counter(:duration_in_millis)
      namespaced_metric.gauge(:name, config_name)

      # Not all the filters will do bufferings
      @flushes = @filter.respond_to?(:flush)
    end

    def toRuby
      self
    end

    def config_name
      @klass.config_name
    end

    def multi_filter(events)
      @metric_events_in.increment(events.size)

      start_time = java.lang.System.nano_time
      new_events = @filter.multi_filter(events)
      @metric_events_time.increment((java.lang.System.nano_time - start_time) / 1_000_000)

      # There is no guarantee in the context of filter
      # that EVENTS_IN == EVENTS_OUT, see the aggregates and
      # the split filter
      c = new_events.count { |event| !event.cancelled? }
      @metric_events_out.increment(c) if c > 0
      new_events
    end

    def has_flush
      @flushes
    end

    def flush(options = {})
      # we also need to trace the number of events
      # coming from a specific filters.
      # Filter plugins that does buffering or spooling of events like the
      # `Logstash-filter-aggregates` can return `NIL` and will flush on the next flush ticks.
      new_events = @filter.flush(options) || []
      @metric_events_out.increment(new_events.size)
      new_events
    end
  end
end
