# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Array < Abstract

      def valid?(value)
        if value.is_a?(Enumerable) && value.is_a?(Array)
          add_errors "Expected array, got #{value.inspect}"
          return false
        end
        return true
      end

    end
  end
end
