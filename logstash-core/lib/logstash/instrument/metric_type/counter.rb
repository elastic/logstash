# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent"

module LogStash module Instrument module MetricType
  class Counter < Base
    def initialize(namespaces, key, value = 0)
      super(namespaces, key)
      @key = key
      @counter = org.logstash.instrument.metrics.Counter.new(value)
    end

    def increment(value = 1)
      @counter.increment(value)
    end

    def decrement(value = 1)
      @counter.decrement(value)
    end

    def execute(action, value = 1)
      @counter.send(action, value)
    end

    def value
      @counter.get
    end

    def java_metric
      @counter
    end
  end
end; end; end
