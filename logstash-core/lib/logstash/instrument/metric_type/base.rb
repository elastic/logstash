# encoding: utf-8
require "logstash/instrument/metric_type/counter"
require "logstash/event"
require "logstash/util"

module LogStash module Instrument module MetricType
  class Base
    def initialize(namespaces, key)
      @namespaces = namespaces
      @key = key
    end

    def to_event(created_at = Time.now)
      LogStash::Event.new(to_hash.merge({ "@timestamp" => created_at }))
    end

    def inspect
      "#{self.class.name} - namespaces: #{namespaces} key: #{@key} value: #{value}"
    end

    protected
    def type
      @type ||= LogStash::Util.class_name(self).downcase
    end
  end
end; end; end
