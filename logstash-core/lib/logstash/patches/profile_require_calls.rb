# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

if ($DEBUGLIST || []).include?("require")
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
        source = caller[0]
        #p source.include?("/lib/polyglot.rb:63:in `require'") => source
        if source.include?("/lib/polyglot.rb:63:in `require'")
          source = caller[1]
        end

        #target = $LOADED_FEATURES.grep(/#{path}/).first
        #puts path
        #puts caller.map { |c| "  #{c}" }.join("\n")
        #fontsize = [10, duration * 48].max
        puts "#{duration},#{path},#{source}"
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
