# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Password < Abstract

      def valid?(value)
        true
      end

    end
  end
end
