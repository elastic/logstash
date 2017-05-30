module LogStash module Instrument
  class MetricFactory
    include org.logstash.instrument.metrics.MetricFactory

    def initialize(metric)
      @metric = metric
    end

    def makeGauge(namespace, key, initial_value)
      gauge = @metric.namespace(keywordize(namespace)).gauge(key.to_sym, initial_value)
      gauge.java_metric
    end

    def makeCounter(namespace, key, initial_value)
      counter = @metric.namespace(keywordize(namespace)).increment(key.to_sym, initial_value)
      counter.java_metric
    end

    private

    def keywordize(namespace)
      namespace.map(&:to_sym)
    end
  end
end; end