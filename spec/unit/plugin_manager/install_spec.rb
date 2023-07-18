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

require 'spec_helper'
require 'pluginmanager/main'
require "pluginmanager/pack_fetch_strategy/repository"

describe LogStash::PluginManager::Install do
  let(:cmd) { LogStash::PluginManager::Install.new("install") }

  context "when validating plugins" do
    let(:sources) { ["https://rubygems.org", "http://localhost:9292"] }

    before(:each) do
      expect(cmd).to receive(:validate_cli_options!).at_least(:once).and_return(nil)
      expect(cmd).to receive(:plugins_gems).and_return([["dummy", nil]])
      expect(cmd).to receive(:update_logstash_mixin_dependencies).and_return(nil)
      expect(cmd).to receive(:install_gems_list!).and_return(nil)
      expect(cmd).to receive(:remove_unused_locally_installed_gems!).and_return(nil)
      cmd.verify = true
    end

    it "should load all the sources defined in the Gemfile" do
      expect(cmd.gemfile.gemset).to receive(:sources).and_return(sources)
      expect(LogStash::PluginManager).to receive(:logstash_plugin?).with("dummy", nil, {:rubygems_source => sources}).and_return(true)
      cmd.execute
    end
  end

  context "when installs alias plugin" do
    before(:each) do
      # mocked to avoid validation of options
      expect(cmd).to receive(:validate_cli_options!).and_return(nil)
      # used to pass indirect input to the command under test
      expect(cmd).to receive(:plugins_gems).and_return([["logstash-input-elastic_agent", nil]])
      expect(cmd).to receive(:update_logstash_mixin_dependencies).and_return(nil)
      # used to skip Bundler interaction
      expect(cmd).to receive(:install_gems_list!).and_return(nil)
      # avoid to clean gemfile folder
      expect(cmd).to receive(:remove_unused_locally_installed_gems!).and_return(nil)
      cmd.verify = true
    end

    it "should not consider as valid plugin a gem with an alias name" do
      expect(LogStash::PluginManager).to receive(:logstash_plugin?).with("logstash-input-elastic_agent", nil, {:rubygems_source => ["https://rubygems.org"]})
      expect(LogStash::PluginManager).to receive(:logstash_plugin?).with("logstash-input-beats", nil, {:rubygems_source => ["https://rubygems.org"]}).and_return(true)

      cmd.execute
    end

    it "should consider as valid plugin a plugin gem with an alias name" do
      expect(LogStash::PluginManager).to receive(:logstash_plugin?).with("logstash-input-elastic_agent", nil, {:rubygems_source => ["https://rubygems.org"]}).and_return(true)
      expect(LogStash::PluginManager).not_to receive(:logstash_plugin?).with("logstash-input-beats", nil, {:rubygems_source => ["https://rubygems.org"]})

      cmd.execute
    end
  end

  context "pack" do
    let(:cmd) { LogStash::PluginManager::Install.new("install my-super-pack") }
    before do
      expect(cmd).to receive(:plugins_arg).and_return(["my-super-pack"]).at_least(:once)
      allow(cmd).to receive(:update_logstash_mixin_dependencies).and_return(nil)
    end

    it "reports `FileNotFoundError` exception" do
      expect(LogStash::PluginManager::InstallStrategyFactory).to receive(:create).with(["my-super-pack"]).and_raise(LogStash::PluginManager::FileNotFoundError)
      expect(cmd).to receive(:report_exception).with(/File not found/, be_kind_of(LogStash::PluginManager::PluginManagerError))
      cmd.execute
    end

    it "reports `InvalidPackError` exception" do
      expect(LogStash::PluginManager::InstallStrategyFactory).to receive(:create).with(["my-super-pack"]).and_raise(LogStash::PluginManager::InvalidPackError)
      expect(cmd).to receive(:report_exception).with(/Invalid pack for/, be_kind_of(LogStash::PluginManager::PluginManagerError))
      cmd.execute
    end

    it "reports any other exceptions" do
      expect(LogStash::PluginManager::InstallStrategyFactory).to receive(:create).with(["my-super-pack"]).and_raise(StandardError)
      expect(cmd).to receive(:report_exception).with(/Something went wrong when installing/, be_kind_of(StandardError))
      cmd.execute
    end
  end
end
