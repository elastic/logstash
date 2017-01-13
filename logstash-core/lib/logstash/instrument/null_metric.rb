# encoding: utf-8
require "logstash/instrument/metric"

module LogStash module Instrument
  # This class is used in the context when we disable the metric collection
  # for specific plugin to replace the `NamespacedMetric` class with this one
  # which doesn't produce any metric to the collector.
  class NullMetric
    attr_reader :namespace_name, :collector

    def initialize(collector = nil)
      @collector = collector
    end

    def increment(namespace, key, value = 1)
      Metric.validate_key!(key)
    end

    def decrement(namespace, key, value = 1)
      Metric.validate_key!(key)
    end

    def gauge(namespace, key, value)
      Metric.validate_key!(key)
    end

    def report_time(namespace, key, duration)
      Metric.validate_key!(key)
    end

    # We have to manually redefine this method since it can return an
    # object this object also has to be implemented as a NullObject
    def time(namespace, key)
      Metric.validate_key!(key)
      if block_given?
        yield
      else
        NullTimedExecution
      end
    end

    def namespace(name)
      raise MetricNoNamespaceProvided if name.nil? || name.empty?
      NamespacedNullMetric.new(self, name)
    end

    def self.validate_key!(key)
      raise MetricNoKeyProvided if key.nil? || key.empty?
    end

    private
    # Null implementation of the internal timer class
    #
    # @see LogStash::Instrument::TimedExecution`
    class NullTimedExecution
      def self.stop
        0
      end
    end
  end
end; end
