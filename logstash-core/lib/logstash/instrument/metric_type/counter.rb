# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent"

module LogStash module Instrument module MetricType
  class Counter < Base
    def initialize(namespaces, key, value = 0)
      super(namespaces, key)

      # TODO
      # This should be a `LongAdder`,
      # will have to create a rubyext for it and support jdk7
      # look at the elasticsearch source code.
      # LongAdder only support decrement of one?
      # Most of the time we will be adding
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

    def to_hash
      { 
        "namespaces" => @namespaces,
        "key" => @key,
        "type" => type,
        "value" => value 
      }
    end
  end
end; end; end
