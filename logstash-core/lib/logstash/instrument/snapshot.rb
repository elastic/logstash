# encoding: utf-8
require "logstash/instrument/metric_type/counter"
require "logstash/util/loggable"
require "logstash/event"

module LogStash module Instrument
  class Snapshot
    include LogStash::Util::Loggable
   
    def initialize
      # The Map doesn't respect the order of insertion
      # we have to track the time another way
      @metrics = Concurrent::Map.new
    end

    def push(*args)
      namespace, key, type, _ = args
      metric = @metrics.fetch_or_store([namespace, key].join('-'), concrete_class(type, key))
      metric.execute(*args)
    end

    def concrete_class(type, key)
      # TODO, benchmark, I think this is faster than using constantize
      case type
      when :counter then MetricType::Counter.new(key)
      end
    end

    def size
      @metrics.size
    end

    def to_event
      LogStash::Event.new({ "message" => "HELLO MEtrics",
                            "size" => @metrics.size })
    end

    def inspect
      "#{self.class.name} - metrics: #{@metrics.values.map(&:inspect)}"
    end
  end
end; end
