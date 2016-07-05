# encoding: utf-8
require "logstash/namespace"
require "cabin"

module LogStash module Util
  module Loggable
    class << self
      def logger=(new_logger)
        @logger = new_logger
      end

      def logger
        @logger ||= org.apache.logging.log4j.LogManager.getLogger("LogStash")
      end
    end

    def self.included(base)
      class << base
        def logger
          Loggable.logger
        end
      end
    end

    def logger
      Loggable.logger
    end
  end
end; end
