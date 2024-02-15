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

shared_examples "integration plugins compatible" do |logstash|
  describe "logstash-plugin install on [#{logstash.human_name}]" do
    let(:plugin) { "logstash-integration-rabbitmq" }
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
      logstash.write_default_pipeline
    end

    after :each do
      logstash.uninstall
    end

    context "when the integration is installed" do
      before(:each) do
        logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
      end
      context "trying to install an inner plugin separately" do
        it "fails to install" do
          result = logstash.run_command_in_path("bin/logstash-plugin install logstash-input-rabbitmq")
          expect(result.stderr).to match(/is already provided by/)
        end
      end
    end
    context "when the integration is not installed" do
      # Muting test. Tracked in https://github.com/elastic/logstash/issues/10459
      xcontext "if an inner plugin is installed" do
        before(:each) do
          logstash.run_command_in_path("bin/logstash-plugin install logstash-input-rabbitmq")
        end
        it "installing the integrations uninstalls the inner plugin" do
          logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
          result = logstash.run_command_in_path("bin/logstash-plugin list logstash-input-rabbitmq")
          expect(result.stdout).to_not match(/^logstash-input-rabbitmq/)
        end
      end
    end
  end

  describe "logstash-plugin uninstall on [#{logstash.human_name}]" do
    let(:plugin) { "logstash-integration-rabbitmq" }
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
      logstash.write_default_pipeline
    end

    after :each do
      logstash.uninstall
    end

    context "when the integration is installed" do
      before(:each) do
        logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
      end
      context "trying to uninstall an inner plugin" do
        it "fails to uninstall it" do
          result = logstash.run_command_in_path("bin/logstash-plugin uninstall logstash-input-rabbitmq")
          expect(result.stderr).to match(/is already provided by/)
        end
      end
    end
  end

  describe "logstash-plugin list on [#{logstash.human_name}]" do
    let(:plugin) { "logstash-integration-rabbitmq" }
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
      logstash.write_default_pipeline
    end

    after :each do
      logstash.uninstall
    end

    context "when the integration is installed" do
      before(:each) do
        logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
      end
      context "listing an integration" do
        let(:result) { logstash.run_command_in_path("bin/logstash-plugin list logstash-integration-rabbitmq") }
        it "shows its inner plugin" do
          expect(result.stdout).to match(/logstash-input-rabbitmq/m)
        end
      end
      context "listing an inner plugin" do
        let(:result) { logstash.run_command_in_path("bin/logstash-plugin list logstash-input-rabbitmq") }
        it "matches the integration that contains it" do
          expect(result.stdout).to match(/logstash-integration-rabbitmq/m)
        end
      end
    end
  end
end
