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
    @metric_events.increment(:in, events.length)
    clock = @metric_events.time(:duration_in_millis)
    @strategy.multi_receive(events)
    clock.stop
    @metric_events.increment(:out, events.length)
  end

  def do_close
    @strategy.do_close
  end
end; end
