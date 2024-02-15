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

shared_examples "logstash update" do |logstash|
  describe "logstash-plugin update on [#{logstash.human_name}]" do
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
      logstash.write_default_pipeline
    end

    after :each do
      logstash.uninstall
    end

    let(:plugin_name) { "logstash-filter-qatest" }
    let(:previous_version) { "0.1.0" }

    before do
      logstash.run_command_in_path("bin/logstash-plugin install --no-verify --version #{previous_version} #{plugin_name}")
      logstash.run_command_in_path("bin/logstash-plugin list")
      expect(logstash).to have_installed?(plugin_name, previous_version)
      # Logstash won't update when we have a pinned version in the gemfile so we remove them
      logstash.replace_in_gemfile(',[[:space:]]"0.1.0"', "")
    end

    context "update a specific plugin" do
      it "has executed successfully" do
        cmd = logstash.run_command_in_path("bin/logstash-plugin update --no-verify #{plugin_name}")
        expect(cmd.stdout).to match(/Updating #{plugin_name}/)
        expect(logstash).to have_installed?(plugin_name, "0.1.1")
        expect(logstash).not_to have_installed?(plugin_name, previous_version)
        expect(logstash).not_to be_running
        with_running_logstash_service(logstash) do
          expect(logstash).to be_running
        end
      end
    end

    context "update all the plugins" do
      it "has executed successfully" do
        logstash.run_command_in_path("bin/logstash-plugin update --no-verify")
        expect(logstash).to have_installed?(plugin_name, "0.1.1")
        expect(logstash).not_to be_running
        with_running_logstash_service(logstash) do
          expect(logstash).to be_running
        end
      end
    end
  end
end
