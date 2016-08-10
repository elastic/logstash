# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Boolean < Abstract

      def valid?(value)
        bool_value = value
        return true  if !!bool_value == bool_value
        if !valid_type?(value)
          add_errors "Expected boolean 'true' or 'false', got #{bool_value.inspect}"
          return false
        end
        true
      end

      private 

      def valid_type?(value)
        ( ( value =~ (/^(true|t|yes|y|1)$/i) ) ||
          ( value.empty? || value =~ (/^(false|f|no|n|0)$/i) ) )
      end

    end
  end
end
