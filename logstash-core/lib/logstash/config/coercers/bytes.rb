# encoding: utf-8
require "logstash/namespace"

module LogStash::Config
  module TypeCoercers
    module Bytes

      def self.coerce(value)
        bytes = Integer(value) rescue nil
        bytes || Filesize.from(value).to_i
      end

    end
  end
end
