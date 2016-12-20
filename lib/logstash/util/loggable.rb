# encoding: utf-8
require "logstash/logging/logger"
require "logstash/namespace"

module LogStash module Util
  module Loggable
    def self.included(klass)

      def klass.log4j_name
        ruby_name = self.name || self.class.name || self.class.to_s
        ruby_name.gsub('::', '.').downcase
      end

      def klass.logger
        @logger ||= LogStash::Logging::Logger.new(log4j_name)
      end

      def klass.slow_logger(warn_threshold, info_threshold, debug_threshold, trace_threshold)
        @slow_logger ||= LogStash::Logging::SlowLogger.new(log4j_name, warn_threshold, info_threshold, debug_threshold, trace_threshold)
      end

      def logger
        self.class.logger
      end

      def slow_logger(warn_threshold, info_threshold, debug_threshold, trace_threshold)
        self.class.slow_logger(warn_threshold, info_threshold, debug_threshold, trace_threshold)
      end
    end
  end
end; end
