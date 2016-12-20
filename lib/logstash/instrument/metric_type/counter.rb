# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent"

module LogStash module Instrument module MetricType
  class Counter < Base
    def initialize(namespaces, key, value = 0)
      super(namespaces, key)

      @counter = Concurrent::AtomicFixnum.new(value)
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
      @counter.value
    end
  end
end; end; end
