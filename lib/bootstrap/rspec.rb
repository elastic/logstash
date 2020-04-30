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

require_relative "environment"
LogStash::Bundler.setup!({:without => [:build]})
require "logstash-core"
require "logstash/environment"

$LOAD_PATH.unshift(File.join(LogStash::Environment::LOGSTASH_CORE, "spec"))

require "rspec/core"
require "rspec"
require 'ci/reporter/rake/rspec_loader'

RSpec.world.reset # if multiple rspec runs occur in a single process, the RSpec "world" state needs to be reset.

status = RSpec::Core::Runner.run(ARGV.empty? ? ($JUNIT_ARGV || ["spec"]) : ARGV).to_i
if ENV["IS_JUNIT_RUN"]
  return status
end
exit status if status != 0
