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
require          'logstash/version'

# This test checks if a package can be installed without errors.
RSpec.shared_examples "installable_with_jdk" do |logstash|
  before(:all) do
    #unset to force it using bundled JDK to run LS
    logstash.run_command("unset LS_JAVA_HOME")
  end

  before(:each) do
    logstash.uninstall
    logstash.install({:bundled_jdk => true, :version => LOGSTASH_VERSION})
    logstash.write_default_pipeline
  end

  after(:each) do
    logstash.uninstall
  end

  it "is installed on [#{logstash.human_name}]" do
    expect(logstash).to be_installed
  end

  it "is running on [#{logstash.human_name}]" do
    with_running_logstash_service(logstash) do
      expect(logstash).to be_running
    end
  end

  it "is removable on [#{logstash.human_name}]" do
    logstash.uninstall
    expect(logstash).to be_removed
  end
end
