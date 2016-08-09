# encoding: utf-8
require "logstash/logging/logger"
require "logstash/namespace"

module LogStash module Util
  module Loggable
    def self.included(klass)
      def klass.logger
        ruby_name = self.is_a?(Module) ? self.name : self.class.name
        log4j_name = ruby_name.gsub('::', '.').downcase
        @logger ||= LogStash::Logging::Logger.new(log4j_name)
      end

      def logger
        self.class.logger
      end
    end
  end
end; end
