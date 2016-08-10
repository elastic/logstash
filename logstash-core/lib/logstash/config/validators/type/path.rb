# encoding: utf-8
require "logstash/namespace"
require_relative "abstract"

module LogStash::Config
  module TypeValidators
    class Path < Abstract

      def valid?(value)
        if !::File.exists?(value)
          add_errors "File does not exist or cannot be opened #{value}"
          return false
        end
        true
      end

    end
  end
end
