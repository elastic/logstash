# encoding: utf-8
module LogStash module Instrument
  class MetricNoKeyProvided < Exception; end

  class Metric
    attr_reader :base_key, :collector

    def initialize(base_key = "", collector)
      @base_key = base_key
      @collector = collector
    end

    def increment(key, value = 1)
      collector.insert([:counter_increment, Time.now, merge_keys(key), value])
    end

    def decrement(key, value = 1)
      collector.insert([:counter_decrement, Time.now, merge_keys(key), value])
    end

    def gauge(key, value)
      collector.insert([:gauge, Time.now, merge_keys(key), value])
    end

    # TODO: Create a NOOP merge if the base key is an empty string
    def merge_keys(key)
      valid_key!(key)
      [@base_key, key).join("-")
    end

    def valid_key!(key)
      raise MetricNoKeyProvided if key.nil? || key == ""
    end

    def namespace(key)
      return Metric.new(merge_keys(key), collector)
    end
  end
end
