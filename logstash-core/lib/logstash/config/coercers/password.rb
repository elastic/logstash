# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Password

      def self.coerce(value)
        return value if value.is_a?(::LogStash::Util::Password)
        ::LogStash::Util::Password.new(value)
      end

    end
  end
end
