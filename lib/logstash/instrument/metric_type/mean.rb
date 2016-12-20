# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent"

module LogStash module Instrument module MetricType
  class Mean < Base
    def initialize(namespaces, key)
      super(namespaces, key)

      @counter = Concurrent::AtomicFixnum.new
      @sum = Concurrent::AtomicFixnum.new
    end

    def increment(value = 1)
      @counter.increment
      @sum.increment(value)
    end

    def decrement(value = 1)
      @counter.decrement
      @sum.decrement(value)
    end

    def mean
      if @counter > 0
        @sum.value / @counter.value
      else
        0
      end
    end
    alias_method :value, :mean
  end
end; end; end
