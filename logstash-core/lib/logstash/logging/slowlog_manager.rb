# encoding: utf-8
require "logstash/namespace"
require "logstash/logging/slow_logger"

module LogStash; module Logging
  class SlowLogManager

    attr_reader :loggers

    def initialize
      @loggers = {}
    end

    def freq_items
      items = {}
      @loggers.each do |key, logger|
        report = {}
        logger.freq_items.top_k.each do |item|
          _key = item[0]
          _report = logger.freq_items.report(_key)
          stats   = _report.delete(:statistics)
          _report[:number_of_events] = item[1]
          _report.merge!(stats.to_hash)
          report[_key] = _report
        end
        items[key] = report
      end
      items
    end

    def top_items
      items = {}
      @loggers.each do |key, logger|
        items[key] = logger.freq_items.top_k_by_time
      end
      items
    end

    def build(type)
      key = nil
      case type
      when :plugin
        key = "slowlog_rolling.plugins"
      else
        raise Exception.new("Unknown logger")
      end
      @loggers[key] = LogStash::Logging::SlowLogger.new(key)
    end
  end
end; end
