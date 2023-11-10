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

  it "starts without unexected warnings" do
    execute = @logstash.run
    lines = execute.stderr_and_stdout.split("\n")
    expect(lines.shift).to match(/^(Using system java)|(Using bundled JDK)|(Using LS_JAVA_HOME defined java):/)
    while (up_line = lines.shift).match(/OpenJDK 64-Bit Server VM warning: Option UseConcMarkSweepGC was deprecated|warning: ignoring JAVA_TOOL_OPTIONS|warning: already initialized constant Socket::Constants|.*warning: method redefined; discarding old to_int$|.*warning: method redefined; discarding old to_f$|^WARNING: Logstash comes bundled with the recommended JDK.*/) do end
    expect(up_line).to match(/^Sending Logstash logs to/)
  end
end
