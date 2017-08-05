require "logstash/output_delegator_strategy_registry"

require "logstash/output_delegator_strategies/shared"
require "logstash/output_delegator_strategies/single"
require "logstash/output_delegator_strategies/legacy"

module LogStash class OutputDelegator
  attr_reader :metric, :metric_events, :strategy, :namespaced_metric, :metric_events, :id

  def initialize(logger, output_class, metric, execution_context, strategy_registry, plugin_args)
    @logger = logger
    @output_class = output_class
    @metric = metric
    @id = plugin_args["id"]

    raise ArgumentError, "No strategy registry specified" unless strategy_registry
    raise ArgumentError, "No ID specified! Got args #{plugin_args}" unless id

    @namespaced_metric = metric.namespace(id.to_sym)
    @namespaced_metric.gauge(:name, config_name)
    @metric_events = @namespaced_metric.namespace(:events)
    @in_counter = @metric_events.counter(:in)
    @out_counter = @metric_events.counter(:out)
    @time_metric = @metric_events.counter(:duration_in_millis)
    @strategy = strategy_registry.
                  class_for(self.concurrency).
                  new(@logger, @output_class, @namespaced_metric, execution_context, plugin_args)
  end

  def config_name
    @output_class.config_name
  end

  def reloadable?
    @output_class.reloadable?
  end

  def concurrency
    @output_class.concurrency
  end

  def register
    @strategy.register
  end

  def multi_receive(events)
    @in_counter.increment(events.length)
    start_time = java.lang.System.current_time_millis
    @strategy.multi_receive(events)
    @time_metric.increment(java.lang.System.current_time_millis - start_time)
    @out_counter.increment(events.length)
  end

  def do_close
    @strategy.do_close
  end
end; end
