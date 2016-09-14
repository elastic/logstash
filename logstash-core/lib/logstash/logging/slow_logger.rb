# encoding: utf-8
require "logstash/namespace"
require "logstash/logging/slow_logger/freq_items"

module LogStash
  module Logging

    class NullLogger
      def log(threshold, time, data={})
      end
      alias_method :warn, :log
    end

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

        cache_elements(threshold, time)
        logger.warn(message, data)
      end
      alias_method :warn, :log

      private

      def cache_elements(threshold, time)
        freq_items.add(threshold, time)
      end

    end

  end
end
