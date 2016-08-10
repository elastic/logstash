# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module NullCoercer

      def self.coerce(value)
        value
      end

    end
  end
end
