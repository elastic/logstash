# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeValidators
    class Abstract

      attr_reader :params

      def initialize(params={})
        @params = params
      end

      def add_errors(message)
        @errors ||= []
        @errors << message
      end

      def errors
        @errors
      end

      private

      def valid_type?(value, klass)
        return true if value.is_a?(klass)
        return true if value.is_a?(::Array) && value.size == 1 && value[0].is_a?(klass)
        false
      end
    end

    class BlockValidator < Abstract

      def initialize(block, params)
        @block  = block
        @params = params
      end

      def valid?(value)
        if !@block.call(value, params)
          add_errors "Validation of #{value} with #{self} failed"
          return false
        end
        return true
      end
    end
  end
end
