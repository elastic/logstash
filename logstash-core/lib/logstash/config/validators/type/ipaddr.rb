# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Ipaddr < Abstract

      def valid?(value)
        octets = value.split(".")
        if octets.length != 4
          add_errors "Expected IPaddr, got #{value.inspect}"
          return false
        end
        octets.each do |o|
          if (o.to_i < 0 || o.to_i > 255)
            add_errors "Expected IPaddr, got #{value.inspect}"
            return false
          end
        end
      end

    end
  end
end
