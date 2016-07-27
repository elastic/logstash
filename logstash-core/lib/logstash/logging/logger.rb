require "logstash/java_integration"

module LogStash
  module Logging
    class Logger
      java_import org.apache.logging.log4j.LogManager
      java_import org.apache.logging.log4j.Logger

      def initialize(name)
        @logger = LogManager.getLogger(name)
      end

      def debug?
        @logger.is_debug_enabled
      end

      def debug(message, data = {})
        @logger.debug(message, data)
      end

      def warn(message, data = {})
        @logger.warn(message, data)
      end

      def info(message, data = {})
        @logger.info(message, data)
      end

      def error(message, data = {})
        @logger.info(message, data)
      end
    end
  end
end
