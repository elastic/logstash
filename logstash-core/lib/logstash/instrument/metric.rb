# encoding: utf-8
require "logstash/instrument/collector"
require "concurrent"

module LogStash module Instrument
  class MetricException < Exception; end
  class MetricNoKeyProvided < MetricException; end
  class MetricNoBlockProvided < MetricException; end
  class MetricNoNamespaceProvided < MetricException; end

  class Metric
    class TimedExecution
      MILLISECONDS = 1_000_000.0.freeze

      def initialize(metric, key)
        @metric = metric
        @key = key
        start
      end

      def start
        @start_time = current_time
      end

      def stop
        @metric.report_time(@key, (MILLISECONDS * (current_time - @start_time)).to_i)
      end

      private
      def current_time
        Time.now
      end
    end

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
      collector.push(namespace_information, key, :gauge, :set, value)
    end

    def time(key)
      validate_key!(key)

      if block_given?
        timer = TimedExecution.new(self, key)
        content = yield
        timer.stop
        return content
      else
        TimedExecution.new(self, key)
      end
    end

    def report_time(key, duration)
      collector.push(namespace_information, key, :mean, :increment, duration)
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
