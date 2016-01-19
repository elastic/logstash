# encoding: utf-8
#
module LogStash
  class FilterDelegator
    extend Forwardable

    def_delegators :@filter,
      :register,
      :close,
      :threadsafe?,
      :do_close,
      :do_stop,
      :periodic_flush

    def initialize(logger, klass, metric, *args)
      options = args.reduce({}, :merge)

      @logger = logger
      @klass = klass
      @filter = klass.new(options)

      # Scope the metrics to the plugin
      @metric = metric.namespace(@filter.id.to_sym)
      @filter.metric = @metric

      define_flush_method if @filter.respond_to?(:flush)
    end

    def config_name
      @klass.config_name
    end

    def multi_filter(events)
      @metric.increment(:events_in, events.size)

      new_events = @filter.multi_filter(events)

      @metric.increment(:events_out, new_events.size)
      return new_events
    end

    private
    def define_flush_method
      define_singleton_method(:flush) do |options = {}|
        @filter.flush(options)
      end
    end
  end
end
