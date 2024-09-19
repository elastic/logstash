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

require_relative "../../../spec_helper"
require "logstash/version"
require "fileutils"

shared_examples "logstash generate" do |logstash|
  before(:each) do
    logstash.install({:version => LOGSTASH_VERSION})
    logstash.write_default_pipeline
  end

  after(:each) do
    logstash.uninstall
  end

  describe "on [#{logstash.human_name}]" do
    GENERATE_TYPES = ["input", "filter", "codec", "output"]
    GENERATE_TYPES.each do |type|
      context "with type #{type}" do
        it "successfully generate the plugin skeleton" do
          command = logstash.run_command_in_path("bin/logstash-plugin generate --type #{type} --name qatest-generated")
          expect(logstash).to File.directory?("logstash-#{type}-qatest-generated")
        end
        it "successfully install the plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install logstash-#{type}-qatest-generated")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-#{type}-qatest-generated")
        end
      end
    end
  end
end
