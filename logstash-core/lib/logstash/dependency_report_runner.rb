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

require_relative "../../../lib/bootstrap/environment"

if $0 == __FILE__
  begin
    LogStash::Bundler.setup!({:without => [:build, :development]})
  rescue => Bundler::GemfileNotFound
    $stderr.puts("No Gemfile found. Maybe you need to run `rake artifact:tar`?")
    raise
  end

  require_relative "../../../lib/bootstrap/patches/jar_dependencies"
  require "logstash/dependency_report"

  exit_status = LogStash::DependencyReport.run
  exit(exit_status || 0)
end
