# encoding: utf-8
require "logstash/instrument/null_metric"

module LogStash module Instrument
  # This class acts a a proxy between the metric library and the user calls.
  #
  # This is the class that plugins authors will use to interact with the `MetricStore`
  # It has the same public interface as `Metric` class but doesnt require to send
  # the namespace on every call.
  #
  # @see Logstash::Instrument::Metric
  class NamespacedNullMetric
    attr_reader :namespace_name
    # Create metric with a specific namespace
    #
    # @param metric [LogStash::Instrument::Metric] The metric instance to proxy
    # @param namespace [Array] The namespace to use
    def initialize(metric = nil, namespace_name = :null)
      @metric = metric
      @namespace_name = Array(namespace_name)
    end

    def increment(key, value = 1)
    end

    def decrement(key, value = 1)
    end

    def gauge(key, value)
    end

    def report_time(key, duration)
    end

    def time(key, &block)
      if block_given?
        yield
      else
        ::LogStash::Instrument::NullMetric::NullTimedExecution
      end
    end

    def collector
      @metric.collector
    end

    def namespace(name)
      NamespacedNullMetric.new(metric, namespace_name + Array(name))
    end

    private
    attr_reader :metric
  end
end; end
