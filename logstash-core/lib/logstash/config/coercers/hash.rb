# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Hash

      def self.coerce(value)
        return value if !value.is_a?(::Enumerable) || value.is_a?(::Hash)
        result = {}
        value.each_slice(2) do |key, _value|
          entry = result[key]
          if entry.nil?
            result[key] = _value
          else
            if entry.is_a?(::Array)
              entry << _value
            else
              result[key] = [entry, _value]
            end
          end
        end
        result
      end

    end
  end
end
