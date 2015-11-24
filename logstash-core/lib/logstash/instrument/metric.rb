# encoding: utf-8
require "logstash/instrument/collector"

module LogStash module Instrument
  class MetricNoKeyProvided < Exception; end

  # TODO: Investigate what could be deferred here,
  class Metric
    attr_reader :collector, :base_key

    def initialize(collector, base_key = nil)
      @collector = collector
      @base_key = base_key
    end

    def increment(key, value = 1)
      collector.push([:counter_increment, Time.now, merge_keys(key), value])
    end

    def decrement(key, value = 1)
      collector.push([:counter_decrement, Time.now, merge_keys(key), value])
    end

    # might be worth to create a block interface for time based gauge
    def gauge(key, value)
      collector.push([:gauge, Time.now, merge_keys(key), value])
    end

    def namespace(key)
      Metric.new(collector, merge_keys(key.to_sym))
    end

    private
    def merge_keys(key)
      valid_key!(key)
      [@base_key, key.to_sym].compact
    end
    
    def valid_key!(key)
      raise MetricNoKeyProvided if key.nil? || key == ""
    end

    def self.create_root(name, collector = LogStash::Instrument::Collector.new)
      LogStash::Instrument::Metric.new(collector, name)
    end
  end
end; end
