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

require_relative "../../framework/fixture"
require_relative "../../framework/settings"
require_relative "../../services/logstash_service"
require_relative "../../framework/helpers"
require_relative "pluginmanager_spec_helper"
require "logstash/devutils/rspec/spec_helper"

describe "CLI > logstash-plugin update", :skip_fips do

  include_context "pluginmanager validation helpers"

  before(:each) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @logstash_plugin = @logstash.plugin_cli
  end

  context "upgrading a plugin" do
    before(:each) do
      aggregate_failures("precheck") do
        expect("logstash-filter-qatest").to_not be_installed_gem
      end
      aggregate_failures("setup") do
        execute = @logstash_plugin.install("logstash-filter-qatest", version: "0.1.0")

        expect(execute.stderr_and_stdout).to match(/Installation successful/)
        expect(execute.exit_code).to eq(0)

        expect("logstash-filter-qatest-0.1.0").to be_installed_gem
      end
    end
    it "upgrades the plugin and cleans the old one" do
      execute = @logstash_plugin.update("logstash-filter-qatest")

      aggregate_failures("command execution") do
        expect(execute.stderr_and_stdout).to include("Updated logstash-filter-qatest 0.1.0 to 0.1.1")
        expect(execute.exit_code).to eq(0)
      end

      installed = @logstash_plugin.list("logstash-filter-qatest", verbose: true)
      expect(execute.exit_code).to eq(0)
      expect(installed.stderr_and_stdout).to include("logstash-filter-qatest")

      expect("logstash-filter-qatest-0.1.1").to be_installed_gem
      expect("logstash-filter-qatest-0.1.0").to_not be_installed_gem
    end
  end
end
