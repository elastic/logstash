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
    # JAR_DEBUG=1 will now show theses
    Jars.debug { "--- jar coordinate #{args[0..-2].join(':')} already loaded with version #{result} - omit version #{args[-1]}" }
    Jars.debug { "    try to load from #{caller.join("\n\t")}" }
    return false
  end
  Jars.debug { "    register #{args.inspect} - #{result == true}" }
  result
end
