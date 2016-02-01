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

    # Get only the instance methods defined in the class
    # and not the whole hierarchy of methods.
    LogStash::Instrument::Metric.public_instance_methods(false).each do |method|
      define_method method do |key, *args|
        metric.send(method, namespace_name, key, *args)
      end
    end

    def namespace(name)
      NamespacedMetric.new(metric, namespace_name.concat(Array(name)))
    end

    private
    attr_reader :metric
  end
end; end
