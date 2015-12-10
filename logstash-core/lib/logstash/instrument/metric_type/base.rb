# encoding: utf-8
require "logstash/instrument/metric_type/counter"
require "logstash/util"

module LogStash module Instrument module MetricType
  class Base
    def initialize(namespaces, key)
      @namespaces = namespaces
      @key = key
    end

    private
    def type
      @type ||= LogStash::Util.class_name(self).downcase
    end
  end
end; end; end
