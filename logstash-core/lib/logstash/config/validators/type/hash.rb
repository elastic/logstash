# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Hash < Abstract

      def valid?(value)
        if !value.is_a?(::Hash)
          if value.is_a?(::Array)
            if value.size % 2 == 1
              add_errors "This field must contain an even number of items, got #{value.size}"
              return false
            end
            return true
          end
          add_errors "Expected hash or array but got #{value.inspect}"
          return false
        end
        return true
      end

    end
  end
end
