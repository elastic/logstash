#!/usr/bin/ruby

require 'rubygems'
require 'find'
require 'json'
require 'lib/log'
require 'Grok'

module LogStash
  class Log
    class TextLog < LogStash::Log
      def initialize(config_params)
        config = config_params.clone
        required_keys = [:name, :grok_pattern]
        optional_keys = [:attrs, :entry_print_format, :index, :sort_keys,
                         :recommended_group_by, :date_key, :date_format]
        check_hash_keys(config, required_keys, optional_keys)

        config[:import_type] = "text"
        config[:entry_print_format] ||= "@LINE"
        @grok_pattern = config.delete(:grok_pattern)
        @date_key = config.delete(:date_key)
        @date_format = config.delete(:date_format)

        @config = config
        @home = ENV["LOGSTASH_HOME"] || "/opt/logstash"

        @grok = Grok.new
        if not File.exists?("#{@home}/patterns")
          throw StandardError.new("#{@home}/patterns directory does not exist")
        end
        Find.find("#{@home}/patterns") do |file|
          next if FileTest.directory?(file)
          @grok.add_patterns_from_file(file)
        end
        @grok.compile(@grok_pattern)
        
        super(config)
      end

      def parse_entry(raw_entry)
        m = @grok.match(raw_entry)

        res = nil
        if m
          res = m.captures
        end
        return nil unless res

        # We're parsing GROK captures, and there are two kinds of outputs:
        #  QUOTEDSTRING:bar - matched pattern QUOTEDSTRING, var named bar, keep
        #  DATA - matched pattern DATA, but no variable name, so we ditch it
        res.keys.each do |key|
          if key =~ /^.+:(.+)$/
            if res[key].length == 1
              res[$1] = res[key][0]
            else
              res[$1] = res[key]
            end
          end
          res.delete(key)
        end

        # add meta @LINE to represent the original input
        res["@LINE"] = raw_entry

        return fix_date(res)
      end
    end # class TextLog
  end
end # module LogStash::Log
