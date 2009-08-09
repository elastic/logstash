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
        required_keys = [:name, :line_format]
        optional_keys = [:attrs, :entry_print_format, :index, :sort_keys,
                         :recommended_group_by, :date_key, :date_format]
        check_hash_keys(config, required_keys, optional_keys)

        config[:import_type] = "text"
        config[:entry_print_format] ||= "@LINE"
        @grok_pattern = config.delete(:grok_pattern)
        @date_key = config.delete(:date_key)
        @date_format = config.delete(:date_format)
        @line_format = config.delete(:line_format)

        @config = config
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
