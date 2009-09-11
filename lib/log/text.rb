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
        config[:encoding] = "text"

        required_keys = REQUIRED_KEYS + [:grok_patterns]
        optional_keys = OPTIONAL_KEYS + []
        check_hash_keys(config, required_keys, optional_keys)

        if not config[:grok_patterns].is_a?(Array)
          throw LogException.new(":grok_patterns must be an array")
        end

        @grok_patterns = config.delete(:grok_patterns)

        super(config)

        if not File.exists?("#{@home}/patterns")
          throw StandardError.new("#{@home}/patterns/ does not exist")
        end

        pattern_files = []
        Find.find("#{@home}/patterns") do |file|
          next if FileTest.directory?(file)
          pattern_files << file
        end

        # initialize groks for each pattern
        @groks = []
        @grok_patterns.each do |pattern|
          grok = Grok.new
          pattern_files.each { |f| grok.add_patterns_from_file(f) }
          grok.compile(pattern)
          @groks << grok
        end
        
      end

      def parse_entry(raw_entry)
        match = nil
        @groks.each do |grok|
          match = grok.match(raw_entry)
          break if match
        end
        return nil unless match
        res = match.captures

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
