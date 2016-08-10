# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Codec < Abstract

      def valid?(value)
        true
      end

    end
  end
end
