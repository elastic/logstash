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

# Bundler + gemspec already setup $LOAD_PATH << '.../lib'
# but since we load specs from 2 locations we need to hook up these:
[LogStash::Environment::LOGSTASH_HOME, LogStash::Environment::LOGSTASH_CORE].each do |path|
  spec_path = File.join(path, "spec")
  $LOAD_PATH.unshift(spec_path) unless $LOAD_PATH.include?(spec_path)
end

require "rspec/core"
require "rspec"
require 'ci/reporter/rake/rspec_loader'

RSpec.clear_examples # if multiple rspec runs occur in a single process, the RSpec "world" state needs to be reset.

status = RSpec::Core::Runner.run(ARGV.empty? ? ($JUNIT_ARGV || ["spec"]) : ARGV).to_i
if ENV["IS_JUNIT_RUN"]
  return status
end
exit status if status != 0
