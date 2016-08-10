# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Array

      def self.coerce(value)
        return value if value.is_a?(::Array)
        Array(value)
      end

    end
  end
end
