# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Number < Abstract

      def valid?(value)
        valid = value.is_a?(::Numeric) || (value.is_a?(::String) && string_number?(value))
        add_errors "Expected number, got #{value.inspect} (type #{value.class})" if !valid
        valid
      end

      private

      def string_number?(v)
        float_number?(v) || integer_number?(v)
      end

      def float_number?(v)
        v.to_s.to_f.to_s == v.to_s
      end

      def integer_number?(v)
        v.to_s.to_i.to_s == v.to_s
      end
    end
  end
end
