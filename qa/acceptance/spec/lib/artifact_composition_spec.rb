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

require_relative '../../../rspec/commands'

describe "artifacts composition" do
  logstash = ServiceTester::Artifact.new()

  before(:each) do
    logstash.install({:version => LOGSTASH_VERSION})
    logstash.write_default_pipeline
  end

  after(:each) do
    logstash.uninstall
  end

  context 'prohibited gem dependencies' do
    it 'does not vendor any version of kramdown' do
      expect(logstash.gem_vendored?('kramdown')).to be false
    end
  end

  context 'necessary gem dependencies (sanity check)' do
    it 'vendors concurrent-ruby' do
      expect(logstash.gem_vendored?('concurrent-ruby')).to be true
    end
  end
end
