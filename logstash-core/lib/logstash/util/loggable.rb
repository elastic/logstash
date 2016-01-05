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
        @logger ||= Cabin::Channel.get(LogStash)
      end
    end

    def self.included(base)
      class << base
        def logger
          @logger || Loggable.logger
        end

        def logger=(new_logger)
          @logger = new_logger
        end
      end
    end

    def logger
      self.class.logger
    end
  end
end; end
