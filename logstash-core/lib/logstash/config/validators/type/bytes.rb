# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Bytes < Abstract

      def valid?(value)
        begin
          bytes = Integer(value) rescue nil
          (bytes || Filesize.from(value).to_i) > 0
        rescue ArgumentError
          add_errors "Unparseable filesize: #{value}. possible units (KiB, MiB, ...) e.g. '10 KiB'. doc reference: http://www.elastic.co/guide/en/logstash/current/configuration.html#bytes"
          return false
        end
      end

    end
  end
end
