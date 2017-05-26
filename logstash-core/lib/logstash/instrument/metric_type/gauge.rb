# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent/atomic_reference/mutex_atomic"
require "logstash/json"

module LogStash module Instrument module MetricType
  class Gauge < org.logstash.instrument.metrics.Gauge
    def execute(action, value = nil)
      self.set(value)
    end

    # We don't want these ruby style methods in java-land
    def get
      self.getValue()
    end

    def set(value)
      self.setValue(value)
    end
  end
end; end; end
