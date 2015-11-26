# encoding: utf-8
require "logstash/instrument/metric_type/counter"
require "logstash/util/loggable"

module LogStash module Instrument
  class Snapshot
    include LogStash::Util::Loggable
   
    def initialize
      # The Map doesn't respect the order of insertion
      # we have to track the time another way
      @metrics = Concurrent::Map.new
    end

    def push(*args)
      type, key, _ = args
      metric = @metrics.fetch_or_store(key, concrete_class(type))
      metric.execute(*args)
    end

    def concrete_class(type)
      # TODO, benchmark, I think this is faster than using constantize
      case type
      when :counter then MetricType::Counter.new
      end
    end

    def size
      @metrics.size
    end
  end
end; end
