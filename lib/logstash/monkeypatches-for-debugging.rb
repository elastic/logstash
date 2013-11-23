# encoding: utf-8
if $DEBUGLIST.include?("require")
  ROOT = File.dirname(__FILE__)
  module Kernel
    alias_method :require_debug, :require

    def require(path)
      start = Time.now
      result = require_debug(path)
      duration = Time.now - start

      origin = caller[1]
      if origin =~ /rubygems\/custom_require/
        origin = caller[3]
        if origin.nil?
          STDERR.puts "Unknown origin"
          STDERR.puts caller.join("\n")
        end
      end
      origin = origin.gsub(/:[0-9]+:in .*/, "") if origin

      # Only print require() calls that did actual work.
      # require() returns true on load, false if already loaded.
      if result
        trace = caller.collect { |c| c.split(":").first }.join(",")
        #puts "#{duration},#{path},#{trace}"
        source = caller[0].split(":").first
        target = $LOADED_FEATURES.grep(/#{path}/).first
        fontsize = [10, duration * 48].max
        puts "#{source.inspect} -> #{target.inspect} [label=\"#{duration}\" labelfontsize=#{fontsize}]"
      end
      #puts caller.map { |c| " => #{c}" }.join("\n")
    end

    alias_method :load_debug, :load

    def load(path)
      puts "load(\"#{path}\")"
      return load_debug(path)
    end
  end
end
