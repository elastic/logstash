# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Codec

      def self.coerce(value)
        if value.is_a?(String)
          return LogStash::Plugin.lookup("codec", value).new
        else
          return value
        end
      end

    end
  end
end
