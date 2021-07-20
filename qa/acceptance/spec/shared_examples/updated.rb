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

# This test checks if the current package could used to update from the latest version released.
RSpec.shared_examples "updated" do |logstash|

  before(:all) { logstash.uninstall }
  after(:all)  do
    logstash.stop_service # make sure the service is stopped
    logstash.uninstall #remove the package to keep uniform state
  end

  before(:each) do
    options={:version => LOGSTASH_LATEST_VERSION, :snapshot => false, :base => "./", :skip_jdk_infix => true }
    logstash.install(options) # make sure latest version is installed
  end

  it "can be updated an run on #{logstash.hostname}" do
    expect(logstash).to be_installed
    # Performing the update
    logstash.install({:version => LOGSTASH_VERSION})
    expect(logstash).to be_installed
    # starts the service to be sure it runs after the upgrade
    logstash.start_service
    Stud.try(40.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(logstash).to be_running
    end
  end
end
