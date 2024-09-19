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

shared_examples "logstash install" do |logstash|
  before(:each) do
    logstash.install({:version => LOGSTASH_VERSION})
    logstash.write_default_pipeline
  end

  after(:each) do
    logstash.uninstall
  end

  describe "on [#{logstash.human_name}]" do
    context "with a direct internet connection" do
      context "when the plugin exist" do
        context "from a local `.GEM` file" do
          let(:gem_name) { "logstash-filter-qatest-0.1.1.gem" }
          let(:gem_tmp_path) { "/tmp/#{gem_name}" }
          before(:each) do
            logstash.download("https://rubygems.org/gems/#{gem_name}", gem_tmp_path)
          end

          after(:each) { logstash.delete_file(gem_tmp_path) }

          it "successfully install the plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install #{gem_tmp_path}")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-dns")
            expect(logstash).not_to be_running
            with_running_logstash_service(logstash) do
              expect(logstash).to be_running
            end
          end
        end

        context "when fetching a gem from rubygems" do
          it "successfully install the plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install logstash-filter-qatest")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-qatest")
            expect(logstash).not_to be_running
            with_running_logstash_service(logstash) do
              expect(logstash).to be_running
            end
          end

          it "successfully install the plugin when verification is disabled" do
            command = logstash.run_command_in_path("bin/logstash-plugin install --no-verify logstash-filter-qatest")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-qatest")
            expect(logstash).not_to be_running
            with_running_logstash_service(logstash) do
              expect(logstash).to be_running
            end
          end

          it "fails when installing a non logstash plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install  bundler")
            expect(command).not_to install_successfully
            expect(logstash).not_to be_running
            with_running_logstash_service(logstash) do
              expect(logstash).to be_running
            end
          end

          it "allow to install a specific version" do
            command = logstash.run_command_in_path("bin/logstash-plugin install --no-verify --version 0.1.0 logstash-filter-qatest")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-qatest", "0.1.0")
            with_running_logstash_service(logstash) do
              expect(logstash).to be_running
            end
          end
        end
      end

      context "when the plugin doesnt exist" do
        it "fails to install and report an error" do
          command = logstash.run_command_in_path("bin/logstash-plugin install --no-verify logstash-output-impossible-plugin")
          expect(command.stderr).to match(/Plugin not found, aborting/)
          with_running_logstash_service(logstash) do
            expect(logstash).to be_running
          end
        end
      end
    end
  end
end
