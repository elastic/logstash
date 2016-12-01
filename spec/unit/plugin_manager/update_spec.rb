# encoding: utf-8
require 'spec_helper'
require 'pluginmanager/main'

describe LogStash::PluginManager::Update do
  let(:cmd)     { LogStash::PluginManager::Update.new("update") }
  let(:sources) { cmd.gemfile.gemset.sources }

  before(:each) do
    expect(cmd).to receive(:find_latest_gem_specs).and_return({})
    allow(cmd).to receive(:warn_local_gems).and_return(nil)
    expect(cmd).to receive(:display_updated_plugins).and_return(nil)
  end

  it "pass all gem sources to the bundle update command" do
    sources = cmd.gemfile.gemset.sources
    expect_any_instance_of(LogStash::Bundler).to receive(:invoke!).with(:update => [], :rubygems_source => sources)
    cmd.execute
  end

  context "when skipping validation" do
    let(:cmd)    { LogStash::PluginManager::Update.new("update") }
    let(:plugin) { OpenStruct.new(:name => "dummy", :options => {} ) }

    before(:each) do
      expect(cmd.gemfile).to receive(:find).with(plugin).and_return(plugin)
      expect(cmd.gemfile).to receive(:save).and_return(nil)
      expect(cmd).to receive(:plugins_to_update).and_return([plugin])
      expect_any_instance_of(LogStash::Bundler).to receive(:invoke!).with(:update => [plugin], :rubygems_source => sources).and_return(nil)
    end

    it "skips version verification when ask for it" do
      cmd.verify = false
      expect(cmd).to_not receive(:validates_version)
      cmd.execute
    end
  end
end
