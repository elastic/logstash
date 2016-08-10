# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Boolean

      def self.coerce(value)
        return value if [TrueClass, FalseClass].include?(value.class)

        return true if value =~ (/^(true|t|yes|y|1)$/i)
        return false if value.empty? || value =~ (/^(false|f|no|n|0)$/i)
        return value
      end

    end
  end
end
