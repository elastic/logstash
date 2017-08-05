# encoding: utf-8
require "logstash/instrument/metric"

module LogStash module Instrument
  # This class acts a a proxy between the metric library and the user calls.
  #
  # This is the class that plugins authors will use to interact with the `MetricStore`
  # It has the same public interface as `Metric` class but doesnt require to send
  # the namespace on every call.
  #
  # @see Logstash::Instrument::Metric
  class NamespacedMetric
    attr_reader :namespace_name
    # Create metric with a specific namespace
    #
    # @param metric [LogStash::Instrument::Metric] The metric instance to proxy
    # @param namespace [Array] The namespace to use
    def initialize(metric, namespace_name)
      @metric = metric
      @namespace_name = Array(namespace_name)
    end

    def increment(key, value = 1)
      @metric.increment(namespace_name, key, value)
    end

    def decrement(key, value = 1)
      @metric.decrement(namespace_name, key, value)
    end

    def gauge(key, value)
      @metric.gauge(namespace_name, key, value)
    end

    def report_time(key, duration)
      @metric.report_time(namespace_name, key, duration)
    end

    def time(key, &block)
      @metric.time(namespace_name, key, &block)
    end

    def collector
      @metric.collector
    end
    
    def counter(key)
      collector.get(@namespace_name, key, :counter)
    end

    def namespace(name)
      NamespacedMetric.new(metric, namespace_name + Array(name))
    end

    private
    attr_reader :metric
  end
end; end
