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

require_relative '../spec_helper'
require_relative '../shared_examples/installed_with_jdk'
require_relative '../shared_examples/updated'

# This tests verify that the generated artifacts could be used properly in a release, implements https://github.com/elastic/logstash/issues/5070
describe "artifacts operation" do
  logstash = ServiceTester::Artifact.new()
  it_behaves_like "installable_with_jdk", logstash
  it_behaves_like "updated", logstash, from_release_branch="7.17"
end
