# encoding: utf-8
require "logstash/util"

module LogStash module Instrument module MetricType
  class Base
    attr_reader :namespaces, :key

    def initialize(namespaces, key)
      @namespaces = namespaces
      @key = key
    end

    def inspect
      "#{self.class.name} - namespaces: #{namespaces} key: #{key} value: #{value}"
    end

    def to_hash
      {
        key => value
      }
    end

    def to_json_data
      value
    end

    def type
      @type ||= LogStash::Util.class_name(self).downcase
    end
  end
end; end; end
