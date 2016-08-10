# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Number

      def self.coerce(value)
        return value if value.is_a?(::Numeric)

        if v.include?(".")
          return value.to_f
        else
          return value.to_i
        end
      end

    end
  end
end
