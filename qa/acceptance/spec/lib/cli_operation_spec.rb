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

require_relative "../spec_helper"
require_relative "../shared_examples/cli/logstash/version"
require_relative "../shared_examples/cli/logstash-plugin/install"
require_relative "../shared_examples/cli/logstash-plugin/list"
require_relative "../shared_examples/cli/logstash-plugin/uninstall"
require_relative "../shared_examples/cli/logstash-plugin/remove"
require_relative "../shared_examples/cli/logstash-plugin/update"
require_relative "../shared_examples/cli/logstash-plugin/generate"
require_relative "../shared_examples/cli/logstash-plugin/integration_plugin"

# This is the collection of test for the CLI interface, this include the plugin manager behaviour,
# it also include the checks for other CLI options.
describe "CLI operation" do
  logstash = ServiceTester::Artifact.new()
  # Force tests to use bundled JDK
  logstash.run_command("unset LS_JAVA_HOME")
  it_behaves_like "logstash version", logstash
  it_behaves_like "logstash install", logstash
  it_behaves_like "logstash list", logstash
  it_behaves_like "logstash uninstall", logstash
  it_behaves_like "logstash remove", logstash
  it_behaves_like "logstash update", logstash
  it_behaves_like "integration plugins compatible", logstash
#    it_behaves_like "logstash generate", logstash
end
