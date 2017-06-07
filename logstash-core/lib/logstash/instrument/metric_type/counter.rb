# encoding: utf-8
require "logstash/instrument/metric_type/base"
require "concurrent"

module LogStash module Instrument module MetricType
  class Counter < org.logstash.instrument.metrics.Counter
    def execute(action, value = 1)
      self.send(action, value)
    end

    # We don't want this ruby style method in java-land
    def value
      self.getValue()
    end
  end
end; end; end
