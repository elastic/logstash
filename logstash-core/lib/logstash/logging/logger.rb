require "logstash/java_integration"

module LogStash
  module Logging
    class Logger
      java_import org.apache.logging.log4j.LogManager
      java_import org.apache.logging.log4j.Logger
      java_import org.apache.logging.log4j.Level
      java_import org.apache.logging.log4j.core.config.LoggerConfig

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

      # Point logging at a specific path.
      def self.configure_logging(path, level)
        logging_ctx = LogManager.getContext(false)
        config = logging_ctx.getConfiguration()
        path ||= LogManager::ROOT_LOGGER_NAME
        level = level.upcase
        if config.getLogger(path)
          loggerConfig = config.getLoggerConfig(path);
          loggerConfig.setLevel(Level::getLevel(level))
        else
          loggerConfig = LoggerConfig.new(path, Level::getLevel(level), true)
          config.addLogger(path, loggerConfig)
        end
        logging_ctx.updateLoggers(config)
      end # def configure_logging
    end
  end
end
