# encoding: utf-8
require "logstash/namespace"
require "logstash/logging/slow_logger/freq_items"

# This module contains necessary classes to handle slow log
# operations.
module LogStash; module Logging

  # Slow log null logger, this logger does
  # nothing when used.
  class NullLogger
    def log(event, threshold, time, data={})
    end
  end

  # Generic slow logger, this class is responsible of
  # reporting to the specific logger and holding an
  # aggregated view of it's reported events.
  class SlowLogger

    attr_reader :logger, :freq_items, :settings

    def initialize(name="loggers.slow", settings=LogStash::SETTINGS, params={})
      @logger     = LogStash::Logging::Logger.new(name)
      @freq_items = LogStash::Logging::Util::FreqItems.new
      @settings   = settings
    end

    def log(event, threshold, took_in_seconds, data={})
      max_time = setting(threshold).to_i
      return if max_time == 0 || took_in_seconds <= max_time

      level, operation_namespace = split_fields(threshold)
      if setting("slowlog.plugins.context")
        data[:event] = event
      end
      data[:threshold] = operation_namespace
      data[:took_in_seconds] = took_in_seconds
      message = "Threshold #{threshold} has been overcome with #{took_in_seconds}"

      freq_items.add(threshold, took_in_seconds)
      to_logger(level.to_sym, message, data)
    end

    def logger=(logger)
      @logger = logger
    end

    private

    def to_logger(level, message, data)
      level = :warn if !logger.respond_to?(level)
      logger.send(level, message, data)
    end

    def split_fields(threshold)
      parts = threshold.split('.')
      [parts[-1], parts[0..-2]]
    end

    def setting(key)
      @settings.get_value(key) rescue nil
    end

  end

end; end
