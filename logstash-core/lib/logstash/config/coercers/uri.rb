# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Uri

      def self.coerce(value)
        return value if value.is_a?(::LogStash::Util::SafeURI)
        ::LogStash::Util::SafeURI.new(value)
      end

    end
  end
end
