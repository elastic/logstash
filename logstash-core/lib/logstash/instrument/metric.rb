# encoding: utf-8
require "logstash/instrument/collector"
require "logstash/instrument/reporter/stdout"
require "concurrent"

module LogStash module Instrument
  class MetricException < Exception; end
  class MetricNoKeyProvided < MetricException; end
  class MetricNoBlockProvided < MetricException; end
  class MetricNoNamespaceProvided < MetricException; end

  class Metric
    attr_reader :collector, :namespace

    def initialize(collector, namespace = nil)
      @collector = collector
      @namespace = Array(namespace).map(&:to_sym)
    end

    def increment(key, value = 1)
      validate_key!(key)
      collector.push(namespace, key, :counter, :increment, Concurrent.monotonic_time, value)
    end

    def decrement(key, value = 1)
      validate_key!(key)
      collector.push(namespace, key, :counter, :decrement, Concurrent.monotonic_time, value)
    end

    # might be worth to create a block interface for time based gauge
    def gauge(key, value)
      validate_key!(key)
      collector.push(namespace, key, :gauge, Concurrent.monotonic_time, value)
    end

    def namespace(sub_namespace)
      raise MetricNoNamespaceProvided if sub_namespace.nil? || sub_namespace.empty?
      Metric.new(collector, merge_keys(sub_namespace))
    end

    # I think this should have his own values.
    def time(key, &block)
      validate_key!(key)
      if block_given?
        start_time = Concurrent.monotonic_time
        content = block.call
        duration = Concurrent.monotonic_time - start_time
        gauge(key, duration)
        return content
      else
        raise MetricNoBlockProvided
      end
    end

    def self.create(namespace, collector = LogStash::Instrument::Collector.instance)
      reporter = LogStash::Instrument::Reporter::Stdout.new(collector)
      Metric.new(collector, namespace)
    end

    private
    def merge_keys(key)
      validate_key!(key)
      @namespace + key.to_sym
    end
    
    def validate_key!(key)
      raise MetricNoKeyProvided if key.nil? || key.empty?
    end
  end
end; end
