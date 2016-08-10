# encoding: utf-8
require "logstash/namespace"

module LogStash::Config

  module Validators

    class AbstractValidator

      attr_reader :config, :plugin_name, :plugin_type

      def initialize(config, plugin_type, plugin_name)
        @plugin_name = plugin_name
        @plugin_type = plugin_type
        @config      = config
        @logger      = Cabin::Channel.get(LogStash)
      end

      def add_error(message)
        @errors ||= []
        @errors << message
      end

      def errors
        @errors
      end

    end

  end
end
