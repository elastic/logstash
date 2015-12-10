# encoding: utf-8
require "concurrent"
module LogStash module Instrument module MetricType
  class Counter
    attr_reader :key
    def initialize(key, value = 0)
      @key = key

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

    def execute(namespace, key, type, action, value)
      @counter.send(action, value)
    end

    def inspect
      "#{self.class.name} - key: #{key} value: #{@counter.value}"
    end
  end
end; end; end
