# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class String < Abstract

      def valid?(value)
        valid = valid_type?(value, ::String)
        if !valid
          add_errors "Expected string, got #{value.inspect}"
        end
        valid
      end

    end
  end
end
