# encoding: utf-8
require "logstash/instrument/collector"
require "concurrent"

module LogStash module Instrument
  class MetricException < Exception; end
  class MetricNoKeyProvided < MetricException; end
  class MetricNoBlockProvided < MetricException; end
  class MetricNoNamespaceProvided < MetricException; end

  class Metric
    attr_reader :collector, :namespace_information

    public
    def initialize(collector, namespace = nil)
      @collector = collector
      @namespace_information = Array(namespace).map(&:to_sym)
    end

    def increment(key, value = 1)
      validate_key!(key)
      collector.push(namespace_information, key, :counter, :increment, value)
    end

    def decrement(key, value = 1)
      validate_key!(key)
      collector.push(namespace_information, key, :counter, :decrement, value)
    end

    # might be worth to create a block interface for time based gauge
    def gauge(key, value)
      validate_key!(key)
      collector.push(namespace_information, key, :gauge, value)
    end

    def time(key, &block)
      validate_key!(key)
      if block_given?
        start_time = Time.now
        content = block.call
        duration = Time.now - start_time
        gauge(key, duration)
        return content
      else
        raise MetricNoBlockProvided
      end
    end

    def namespace(sub_namespace)
      raise MetricNoNamespaceProvided if sub_namespace.nil? || sub_namespace.empty?

      new_namespace = namespace_information.clone
      new_namespace << sub_namespace

      Metric.new(collector, new_namespace)
    end

    def self.create(namespace, collector = LogStash::Instrument::Collector.instance)
      Metric.new(collector, namespace)
    end

    private
    def validate_key!(key)
      raise MetricNoKeyProvided if key.nil? || key.empty?
    end
  end
end; end
