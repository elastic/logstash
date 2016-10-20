# encoding: utf-8
require 'spec_helper'
require 'pluginmanager/main'
require "pluginmanager/pack_fetch_strategy/repository"

describe LogStash::PluginManager::Install do
  let(:cmd) { LogStash::PluginManager::Install.new("install") }

  context "when validating plugins" do
    before(:each) do
      expect(cmd).to receive(:validate_cli_options!).and_return(nil)
    end

    before do
      expect(LogStash::PluginManager::PackFetchStrategy::Repository).to receive(:get_installer_for).with(anything).and_return(nil)
    end

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

  context "pack" do
    let(:cmd) { LogStash::PluginManager::Install.new("install my-super-pack") }
    before do
      expect(cmd).to receive(:plugins_arg).and_return(["my-super-pack"]).at_least(:once)
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
