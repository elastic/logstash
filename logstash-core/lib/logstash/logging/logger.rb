require "logstash/java_integration"

module LogStash
  module Logging
    class Logger
      java_import org.apache.logging.log4j.Level
      java_import org.apache.logging.log4j.LogManager
      java_import org.apache.logging.log4j.core.config.Configurator
      @@config_mutex = Mutex.new
      @@logging_context = nil

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

      def self.configure_logging(level, path = LogManager::ROOT_LOGGER_NAME)
        @@config_mutex.synchronize { Configurator.setLevel(path, Level.valueOf(level)) }
      rescue Exception => e
        raise ArgumentError, "invalid level[#{level}] for logger[#{path}]"
      end

      def self.initialize(config_location)
        @@config_mutex.synchronize do
          if @@logging_context.nil?
            @@logging_context = Configurator.initialize(nil, config_location)
          end
        end
      end

      def self.get_logging_context
        return @@logging_context
      end
    end
  end
end
