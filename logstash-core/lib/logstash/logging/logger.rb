require "logstash/java_integration"
require "uri"

module LogStash
  module Logging
    java_import org.apache.logging.log4j.Level
    java_import org.apache.logging.log4j.LogManager
    java_import org.apache.logging.log4j.core.config.Configurator
    java_import org.apache.logging.log4j.core.config.DefaultConfiguration

    class Logger
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
            file_path = URI(config_location).path
            if ::File.exists?(file_path)
              logs_location = java.lang.System.getProperty("ls.logs")
              puts "Sending Logstash's logs to #{logs_location} which is now configured via log4j2.properties"
              @@logging_context = Configurator.initialize(nil, config_location)
            else
              # fall back to default config
              puts "Could not find log4j2 configuration at path #{file_path}. Using default config which logs to console"
              @@logging_context = Configurator.initialize(DefaultConfiguration.new)
            end
          end
        end
      end

      def self.get_logging_context
        return @@logging_context
      end
    end

    class SlowLogger
      def initialize(name, warn_threshold, info_threshold, debug_threshold, trace_threshold)
        slowlog_name = ["slowlog", name].join('.')
        @slowlogger = LogManager.getLogger(slowlog_name)
        @warn_threshold = warn_threshold
        @info_threshold = info_threshold
        @debug_threshold = debug_threshold
        @trace_threshold = trace_threshold
      end

      def as_data(plugin_params, event, took_in_nanos)
        {
          :plugin_params => plugin_params,
          :took_in_nanos => took_in_nanos,
          :took_in_millis => took_in_nanos / 1000000,
          :event => event.to_json
        }
      end

      def on_event(message, plugin_params, event, took_in_nanos)
        if @warn_threshold >= 0 and took_in_nanos > @warn_threshold
          @slowlogger.warn(message, as_data(plugin_params, event, took_in_nanos))
        elsif @info_threshold >= 0 and took_in_nanos > @info_threshold
          @slowlogger.info(message, as_data(plugin_params, event, took_in_nanos))
        elsif @debug_threshold >= 0 and took_in_nanos > @debug_threshold
          @slowlogger.debug(message, as_data(plugin_params, event, took_in_nanos))
        elsif @trace_threshold >= 0 and took_in_nanos > @trace_threshold
          @slowlogger.trace(message, as_data(plugin_params, event, took_in_nanos))
        end
      end
    end
  end
end
