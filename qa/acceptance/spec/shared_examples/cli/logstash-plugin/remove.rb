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

shared_examples "logstash remove" do |logstash|
  describe "logstash-plugin remove on [#{logstash.human_name}]" do
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
      logstash.write_default_pipeline
    end

    after :each do
      logstash.uninstall
    end

    context "when the plugin isn't installed" do
      it "fails to remove it" do
        result = logstash.run_command_in_path("bin/logstash-plugin remove logstash-filter-qatest")
        expect(result.stderr).to match(/This plugin has not been previously installed/)
      end
    end

    context "when the plugin is installed" do
      it "successfully removes it" do
        result = logstash.run_command_in_path("bin/logstash-plugin install logstash-filter-qatest")
        expect(logstash).to have_installed?("logstash-filter-qatest")

        result = logstash.run_command_in_path("bin/logstash-plugin remove logstash-filter-qatest")
        expect(logstash).not_to have_installed?("logstash-filter-qatest")
        expect(logstash).not_to be_running
        with_running_logstash_service(logstash) do
          expect(logstash).to be_running
        end
      end
    end
  end
end
