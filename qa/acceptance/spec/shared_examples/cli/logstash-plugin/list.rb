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

shared_examples "logstash list" do |logstash|
  describe "logstash-plugin list on [#{logstash.human_name}]" do
    before(:all) do
      logstash.install({:version => LOGSTASH_VERSION})
      logstash.write_default_pipeline
    end

    after(:all) do
      logstash.uninstall
    end

    let(:plugin_name) { /logstash-(?<type>\w+)-(?<name>\w+)/ }
    let(:plugin_name_with_version) { /(\s*[├└]──\s*)?#{plugin_name}\s(\(\d+\.\d+.\d+(.\w+)?\)|\(alias\))/ }

    context "without a specific plugin" do
      it "display a list of plugins" do
        result = logstash.run_command_in_path("bin/logstash-plugin list")
        expect(result.stdout.split("\n").size).to be > 1
      end

      it "display a list of installed plugins" do
        result = logstash.run_command_in_path("bin/logstash-plugin list --installed")
        expect(result.stdout.split("\n").size).to be > 1
      end

      it "list the plugins with their versions" do
        result = logstash.run_command_in_path("bin/logstash-plugin list --verbose")

        stdout = StringIO.new(result.stdout)
        stdout.set_encoding(Encoding::UTF_8)
        while line = stdout.gets
          next if line.match(/^Using system java:.*$/) || line.match(/^Using bundled JDK:.*$/)
          match = line.match(/^#{plugin_name_with_version}$/)
          expect(match).to_not be_nil

          # Integration Plugins list their sub-plugins, e.g.,
          # ~~~
          # logstash-integration-kafka (10.0.0)
          # ├── logstash-input-kafka
          # └── logstash-output-kafka
          # ~~~
          if match[:type] == 'integration'
            while line = stdout.gets
              match = line.match(/^(?: [├└]──\s+)#{plugin_name}$/)
              expect(match).to_not be_nil
              break if line.start_with?(' └')
            end
          end
        end
      end
    end

    context "with a specific plugin" do
      let(:plugin_name) { "logstash-input-stdin" }
      it "list the plugin and display the plugin name" do
        result = logstash.run_command_in_path("bin/logstash-plugin list #{plugin_name}")
        expect(result).to run_successfully_and_output(/^#{plugin_name}$/)
      end

      it "list the plugin with his version" do
        result = logstash.run_command_in_path("bin/logstash-plugin list --verbose #{plugin_name}")
        expect(result).to run_successfully_and_output(/^#{plugin_name} \(\d+\.\d+.\d+\)/)
      end
    end
  end
end
