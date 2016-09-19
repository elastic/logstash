# encoding: utf-8
require "logstash/namespace"
require "logstash/logging/slow_logger/freq_items"

# This module contains necessary classes to handle slow log
# operations.
module LogStash; module Logging

  # Slow log null logger, this logger does
  # nothing when used.
  class NullLogger
    def log(threshold, time, data={})
    end
    alias_method :warn, :log
  end

  # Generic slow logger, this class is responsible of
  # reporting to the specific logger and holding an
  # aggregated view of it's reported events.
  class SlowLogger

    attr_reader :logger, :freq_items

    def initialize(name="loggers.slow", params={})
      @logger     = LogStash::Logging::Logger.new(name)
      @freq_items = LogStash::Logging::Util::FreqItems.new
    end

    def log(threshold, time, data={})
      message          = data.delete(:message)
      data[:threshold] = threshold
      data[:time]      = time

      freq_items.add(threshold, time)
      logger.warn(message, data)
    end
    alias_method :warn, :log

  end

end; end
