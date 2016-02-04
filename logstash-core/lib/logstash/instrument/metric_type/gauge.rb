# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent/atomic_reference/mutex_atomic"
require "logstash/json"

module LogStash module Instrument module MetricType
  class Gauge < Base
    def initialize(namespaces, key)
      super(namespaces, key)

      @gauge = Concurrent::MutexAtomicReference.new()
    end

    def execute(action, value = nil)
      @gauge.set(value)
    end

    def value
      @gauge.get
    end
  end
end; end; end
