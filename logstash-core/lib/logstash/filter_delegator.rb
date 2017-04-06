# encoding: utf-8
#
module LogStash
  class FilterDelegator
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

    def initialize(logger, klass, metric, execution_context, plugin_args)
      @logger = logger
      @klass = klass
      @id = plugin_args["id"]
      @filter = klass.new(plugin_args)

      # Scope the metrics to the plugin
      namespaced_metric = metric.namespace(@id.to_sym)
      @filter.metric = namespaced_metric
      @filter.execution_context = execution_context

      @metric_events = namespaced_metric.namespace(:events)
      namespaced_metric.gauge(:name, config_name)

      # Not all the filters will do bufferings
      define_flush_method if @filter.respond_to?(:flush)
    end

    def config_name
      @klass.config_name
    end

    def multi_filter(events)
      @metric_events.increment(:in, events.size)

      clock = @metric_events.time(:duration_in_millis)
      new_events = @filter.multi_filter(events)
      clock.stop

      # There is no guarantee in the context of filter
      # that EVENTS_INT == EVENTS_OUT, see the aggregates and
      # the split filter
      c = new_events.count { |event| !event.cancelled? }
      @metric_events.increment(:out, c) if c > 0

      return new_events
    end

    private
    def define_flush_method
      define_singleton_method(:flush) do |options = {}|
        # we also need to trace the number of events
        # coming from a specific filters.
        new_events = @filter.flush(options)

        # Filter plugins that does buffering or spooling of events like the
        # `Logstash-filter-aggregates` can return `NIL` and will flush on the next flush ticks.
        @metric_events.increment(:out, new_events.size) if new_events && new_events.size > 0
        new_events
      end
    end
  end
end
