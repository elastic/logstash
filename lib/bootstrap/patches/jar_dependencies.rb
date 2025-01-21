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

require "jar_dependencies"

def require_jar(*args)
  return nil unless Jars.require?
  result = Jars.require_jar(*args)
  if result.is_a? String
    # JARS_VERBOSE=true will show these
    Jars.debug { "--- jar coordinate #{args[0..-2].join(':')} already loaded with version #{result} - omit version #{args[-1]}" }
    Jars.debug { "    try to load from #{caller.join("\n\t")}" }
    return false
  end
  Jars.debug { "    register #{args.inspect} - #{result == true}" }
  result
end

# work around https://github.com/jruby/jruby/issues/8579
# the ruby maven 3.9.3 + maven-libs 3.9.9 gems will output unnecessary text we need to trim down during `load_from_maven`
# remove everything from "--" until the end of the line
# the `[...-5]` is just to remove the color changing characters from the end of the string that exist before "--"
require 'jars/installer'

class ::Jars::Installer
  def self.load_from_maven(file)
    Jars.debug { "[load_from_maven] called with arguments: #{file.inspect}" }
    result = []
    ::File.read(file).each_line do |line|
      if line.match?(/ --/)
        Jars.debug { "[load_from_maven] line: #{line.inspect}" }
        fixed_line = line.strip.gsub(/ --.+?$/, "")[0...-5]
        Jars.debug { "[load_from_maven] fixed_line: #{fixed_line.inspect}" }
        dep = ::Jars::Installer::Dependency.new(fixed_line)
      else
        dep = ::Jars::Installer::Dependency.new(line)
      end
      result << dep if dep && dep.scope == :runtime
    end
    Jars.debug { "[load_from_maven] returned: #{result.inspect}" }
    result
  end
end
