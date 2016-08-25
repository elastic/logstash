require "logstash/java_integration"

module LogStash
  module Logging
    class Logger
      java_import org.apache.logging.log4j.Level
      java_import org.apache.logging.log4j.LogManager
      java_import org.apache.logging.log4j.core.config.Configurator

      def initialize(name)
        @logger = LogManager.getLogger(name)
      end

      def debug?
        @logger.is_debug_enabled
      end

      def info?
        @logger.is_info_enabled
      end

      def error?
        @logger.is_error_enabled
      end

      def warn?
        @logger.is_warn_enabled
      end

      def fatal?
        @logger.is_fatal_enabled
      end

      def trace?
        @logger.is_trace_enabled
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
        @logger.error(message, data)
      end

      def fatal(message, data = {})
        @logger.fatal(message, data)
      end

      def trace(message, data = {})
        @logger.trace(message, data)
      end

      # Point logging at a specific path.
      def self.configure_logging(level, path = LogManager::ROOT_LOGGER_NAME)
        Configurator.setLevel(path, Level.toLevel(level))
      end # def configure_logging

      def self.initialize(config_location)
        Configurator.initialize(nil, config_location)
      end
    end
  end
end
