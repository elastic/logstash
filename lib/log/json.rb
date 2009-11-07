#!/usr/bin/ruby

require 'rubygems'
require 'erb'
require 'json'
require 'lib/log'

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
        # need to add @LINE
        res = collapse(JSON.parse(raw_entry))
        res["@LINE"] = template(@line_format, res)
        fix_date(res)

        return res
      end

      private
      def template(fmt, entry)
        erb = ERB.new(fmt)
        return erb.result(binding)
      end

      private
      def collapse(hash)
        hash.each do |k, v|
          if v.is_a?(Hash)
            hash.delete(k)
            collapse(v).each do |k2, v2|
              hash["#{k}/#{k2}"] = v2
            end
          elsif v.is_a?(Array)
            hash[k] = v.inspect
          elsif not v.is_a?(String)
            hash[k] = v.to_s
          end
        end

        return hash
      end
    end # class JsonLog
  end
end # module LogStash::Log
