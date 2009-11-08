#!/usr/bin/ruby

require 'rubygems'
require 'erb'
require 'json'
require 'lib/log'
require 'lib/util'

module LogStash
  class Log
    class JsonLog < LogStash::Log
      def initialize(config_params)
        config = config_params.clone
        config[:encoding] = "json"

        required_keys = REQUIRED_KEYS + [:line_format]
        optional_keys = OPTIONAL_KEYS + []
        check_hash_keys(config, required_keys, optional_keys)

        @line_format = config.delete(:line_format)

        super(config)
      end

      def parse_entry(raw_entry)
        begin
          res = LogStash::Util::collapse(JSON.parse(raw_entry))
        rescue JSON::ParserError
          raise LogParseError.new("Invalid JSON: #{$!}: #{raw_entry}")
        end
        res["@LINE"] = template(@line_format, res)
        fix_date(res)

        return res
      end

      private
      def template(fmt, entry)
        erb = ERB.new(fmt)
        return erb.result(binding)
      end # def template
    end # class JsonLog
  end
end # module LogStash::Log
