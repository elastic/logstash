# encoding: utf-8
require "logstash/instrument/collector"
require "logstash/instrument/reporter/stdout"
require "concurrent"

module LogStash module Instrument
  class MetricNoKeyProvided < Exception; end
  class MetricNoBlockProvided < Exception; end

  class Metric
    attr_reader :collector, :base_key

    def initialize(collector, base_key = nil)
      @collector = collector
      @base_key = base_key
    end

    def increment(key, value = 1)
      collector.push(:counter, merge_keys(key), :increment, Concurrent.monotonic_time, value)
    end

    def decrement(key, value = 1)
      collector.push(:counter, merge_keys(key), :decrement, Concurrent.monotonic_time, value)
    end

    # might be worth to create a block interface for time based gauge
    def gauge(key, value)
      collector.push(:gauge, merge_keys(key), Concurrent.monotonic_time, value)
    end

    def namespace(key)
      Metric.new(collector, merge_keys(key.to_sym))
    end

    # I think this should have his own values.
    def time(key, &block)
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

    # TODO
    # Externalize this
    def self.create_root(name, collector = LogStash::Instrument::Collector.new)
      # reporter =  LogStash::Instrument::Reporter::File.new(collector)
      reporter = LogStash::Instrument::Reporter::Stdout.new(collector)
      Metric.new(collector, name)
    end

    private
    def merge_keys(key)
      valid_key!(key)
      [@base_key, key.to_sym]
    end
    
    def valid_key!(key)
      raise MetricNoKeyProvided if key.nil? || key == ""
    end
  end
end; end
