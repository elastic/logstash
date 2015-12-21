# encoding: utf-8
#
module LogStash
  class FilterDelegator
    extend Forwardable

    def_delegators :@filter,
      :register,
      :close,
      :multi_filter,
      :threadsafe?,
      :do_close,
      :do_stop,
      :periodic_flush

    def initialize(logger, klass, metric, *args)
      options = args.reduce({}, :merge)

      @logger = logger
      @klass = klass
      @metric = metric
      @filter = klass.new(options)

      define_flush if @filter.respond_to?(:flush)
    end

    def config_name
      @klass.config_name
    end

    private
    def define_flush
      define_singleton_method(:flush) do |options = {}|
        @filter.flush(options)
      end
    end
  end
end
