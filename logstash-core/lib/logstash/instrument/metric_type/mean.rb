# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent"

module LogStash module Instrument module MetricType
  class Mean < LogStash::Instrument::MetricType::Base
    def initialize(namespaces, key)
      super(namespaces, key)

      @counter = Concurrent::AtomicFixnum.new
      @sum = Concurrent::AtomicFixnum.new
    end

    def increment(value = 1)
      @counter.increment
      @sum.increment(value = 1)
    end

    def decrement(value = 1)
      @counter.decrement
      @sum.decrement(value)
    end

    def mean
      @sum.value / @counter.value
    end

    def to_hash
      { 
        "namespaces" => @namespaces,
        "key" => @key,
        "type" => type,
        "value" => mean
      }
    end
  end
end; end; end
