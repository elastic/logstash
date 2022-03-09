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

require_relative "../framework/fixture"
require_relative "../framework/settings"
require_relative "../framework/helpers"

describe "CLI >" do

  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
  end

  after(:each) { @logstash.teardown }

  it "shows --help" do
    execute = @logstash.run('--help')

    expect(execute.exit_code).to eq(0)
    expect(execute.stderr_and_stdout).to include('bin/logstash [OPTIONS]')
    expect(execute.stderr_and_stdout).to include('--pipeline.id ID')
  end

  it "does not warn about GC" do
    execute = @logstash.run
    puts execute.stderr_and_stdout
    expect(execute.stderr_and_stdout).not_to include('OpenJDK 64-Bit Server VM warning: Option UseConcMarkSweepGC was deprecated in version 9.0 and will likely be removed in a future release.')
  end
end
