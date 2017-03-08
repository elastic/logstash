# encoding: utf-8
require "logstash/instrument/collector"
require "concurrent"

module LogStash module Instrument
  class MetricException < Exception; end
  class MetricNoKeyProvided < MetricException; end
  class MetricNoBlockProvided < MetricException; end
  class MetricNoNamespaceProvided < MetricException; end

  # This class provide the interface between the code, the collector and the format
  # of the recorded metric.
  class Metric
    attr_reader :collector

    def initialize(collector)
      @collector = collector
    end

    def increment(namespace, key, value = 1)
      self.class.validate_key!(key)
      collector.push(namespace, key, :counter, :increment, value)
    end

    def decrement(namespace, key, value = 1)
      self.class.validate_key!(key)
      collector.push(namespace, key, :counter, :decrement, value)
    end

    def gauge(namespace, key, value)
      self.class.validate_key!(key)
      collector.push(namespace, key, :gauge, :set, value)
    end

    def time(namespace, key)
      self.class.validate_key!(key)

      if block_given?
        timer = TimedExecution.new(self, namespace, key)
        content = yield
        timer.stop
        return content
      else
        TimedExecution.new(self, namespace, key)
      end
    end

    def report_time(namespace, key, duration)
      self.class.validate_key!(key)
      collector.push(namespace, key, :counter, :increment, duration)
    end

    # This method return a metric instance tied to a specific namespace
    # so instead of specifying the namespace on every call.
    #
    # Example:
    #   metric.increment(:namespace, :mykey, 200)
    #   metric.increment(:namespace, :mykey_2, 200)
    #
    #   namespaced_metric = metric.namespace(:namespace)
    #   namespaced_metric.increment(:mykey, 200)
    #   namespaced_metric.increment(:mykey_2, 200)
    # ```
    #
    # @param name [Array<String>] Name of the namespace
    # @param name [String] Name of the namespace
    def namespace(name)
      raise MetricNoNamespaceProvided if name.nil? || name.empty?

      NamespacedMetric.new(self, name)
    end

    def self.validate_key!(key)
      raise MetricNoKeyProvided if key.nil? || key.empty?
    end

    private
    # Allow to calculate the execution of a block of code.
    # This class support 2 differents syntax a block or the return of
    # the object itself, but in the later case the metric won't be recorded
    # Until we call `#stop`.
    #
    # @see LogStash::Instrument::Metric#time
    class TimedExecution
      MILLISECONDS = 1_000.0.freeze

      def initialize(metric, namespace, key)
        @metric = metric
        @namespace = namespace
        @key = key
        start
      end

      def start
        @start_time = Time.now
      end

      def stop
        execution_time = (MILLISECONDS * (Time.now - @start_time)).to_i
        @metric.report_time(@namespace, @key, execution_time)
        execution_time
      end
    end
  end
end; end
