# encoding: utf-8
require 'spec_helper'
require 'pluginmanager/main'

describe LogStash::PluginManager::Install do
  let(:cmd) { LogStash::PluginManager::Install.new("install") }

  before(:each) do
    expect(cmd).to receive(:validate_cli_options!).and_return(nil)
  end

  context "when validating plugins" do
    let(:sources) { ["https://rubygems.org", "http://localhost:9292"] }

    before(:each) do
      expect(cmd).to receive(:plugins_gems).and_return([["dummy", nil]])
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
end
