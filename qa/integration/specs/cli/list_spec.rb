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

require_relative '../../framework/fixture'
require_relative '../../framework/settings'
require_relative '../../services/logstash_service'
require_relative '../../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

# SPLIT_ESTIMATE: 24
describe "CLI > logstash-plugin remove" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash_plugin = @fixture.get_service("logstash").plugin_cli
  end

  context "listing plugins" do

    let(:sub_heading_pattern) do
      Regexp.union(" ├──"," └──")
    end

    let(:version_pattern) do
      /[0-9]+[.][0-9][0-9a-z.]+/
    end

    def parse_output(output)
      output.split(/\n(?! )/)
    end

    context "--verbose" do
      it "successfully lists a single plugin" do
        list_command = @logstash_plugin.run("list --verbose logstash-integration-jdbc")
        expect(list_command.exit_code).to eq(0)
        expect(list_command.stderr_and_stdout).to match(/^logstash-integration-jdbc [(]#{version_pattern}[)]/)
      end
      it "successfully lists all plugins" do
        list_command = @logstash_plugin.run("list --verbose")
        expect(list_command.exit_code).to eq(0)
        expect(list_command.stderr_and_stdout).to match(/^logstash-integration-jdbc [(]#{version_pattern}[)]/)
        expect(list_command.stderr_and_stdout).to match(/^logstash-input-beats [(]#{version_pattern}[)]/)
        expect(list_command.stderr_and_stdout).to match(/^logstash-output-elasticsearch [(]#{version_pattern}[)]/)
      end
    end

    it "expands integration plugins" do
      list_command = @logstash_plugin.run("list logstash-integration-jdbc")
      expect(list_command.exit_code).to eq(0)
      plugins = list_command.stderr_and_stdout.split(/\n(?! )/)

      integration_plugin = plugins.find { |plugin_output| plugin_output.match(/^logstash-integration-jdbc\b/) }
      expect(integration_plugin).to match(/^#{sub_heading_pattern} #{Regexp.escape("logstash-input-jdbc")}$/)
      expect(integration_plugin).to match(/^#{sub_heading_pattern} #{Regexp.escape("logstash-filter-jdbc_static")}$/)
    end

    it "expands plugin aliases" do
      list_command = @logstash_plugin.run("list logstash-input-beats")
      expect(list_command.exit_code).to eq(0)
      plugins = list_command.stderr_and_stdout.split(/\n(?! )/)

      alias_plugin = plugins.find { |plugin_output| plugin_output.match(/^logstash-input-beats\b/) }
      expect(alias_plugin).to match(/^#{sub_heading_pattern} #{Regexp.escape("logstash-input-elastic_agent (alias)")}$/)
    end

    context "--no-expand" do
      it "does not expand integration plugins" do
        list_command = @logstash_plugin.run("list --no-expand")
        expect(list_command.exit_code).to eq(0)
        expect(list_command.stderr_and_stdout).to match(/^logstash-integration-jdbc\b/)
        expect(list_command.stderr_and_stdout).to_not include("logstash-input-jdbc") # known integrated plugin
        expect(list_command.stderr_and_stdout).to_not include("logstash-filter-jdbc") # known integrated plugin
      end
      it "does not expand plugin aliases" do
        list_command = @logstash_plugin.run("list --no-expand")
        expect(list_command.exit_code).to eq(0)
        expect(list_command.stderr_and_stdout).to match(/^logstash-input-beats\b/)
        expect(list_command.stderr_and_stdout).to_not include("logstash-input-elastic_agent") # known alias
      end
    end
  end
end
