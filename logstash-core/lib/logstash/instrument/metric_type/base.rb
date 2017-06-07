# encoding: utf-8
require "logstash/util"

module LogStash module Instrument module MetricType
  # This is here for backwards compatibility.
  # Some tests and perhaps even user code check for class identity
  # We should remove this in master/6.0
  Base = org.logstash.instrument.metrics.AbstractMetric
end; end; end
