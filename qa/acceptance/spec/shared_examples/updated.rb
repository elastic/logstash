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
require_relative '../../helpers'
require          'logstash/version'

# This test checks if the current package could used to update from the latest version released.
RSpec.shared_examples "updated" do |logstash, from_release_branch|
  before(:all) {
    #unset to force it using bundled JDK to run LS
    logstash.run_command("unset LS_JAVA_HOME")
    logstash.uninstall
  }
  after(:all)  do
    logstash.stop_service # make sure the service is stopped
    logstash.uninstall #remove the package to keep uniform state
  end

  before(:each) do
    latest_logstash_release_version = fetch_latest_logstash_release_version(from_release_branch)
    url, dest = logstash_download_metadata(latest_logstash_release_version, logstash.client.architecture_extension, logstash.client.package_extension).values_at(:url, :dest)
    logstash.download(url, dest)
    options = {:version => latest_logstash_release_version, :snapshot => false, :base => "./", :skip_jdk_infix => false }
    logstash.install(options)
    logstash.write_default_pipeline
  end

  it "can be updated and run on [#{logstash.human_name}]" do
    expect(logstash).to be_installed
    # Performing the update
    logstash.install({:version => LOGSTASH_VERSION})
    logstash.write_default_pipeline
    expect(logstash).to be_installed
    # starts the service to be sure it runs after the upgrade
    with_running_logstash_service(logstash) do
      expect(logstash).to be_running
    end
  end
end
