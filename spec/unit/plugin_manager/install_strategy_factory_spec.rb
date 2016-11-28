# encoding: utf-8
require "pluginmanager/install_strategy_factory"

describe LogStash::PluginManager::InstallStrategyFactory do
  subject { described_class }
  let(:plugins_args) { [ "logstash-pack-mega" ] }

  it "returns the first matched strategy" do
    success = double("urifetch success")

    expect(LogStash::PluginManager::PackFetchStrategy::Uri).to receive(:get_installer_for).with(plugins_args.first).and_return(success)
    expect(subject.create(plugins_args)).to eq(success)
  end

  it "returns the matched strategy" do
    success = double("elastic xpack success")

    expect(LogStash::PluginManager::PackFetchStrategy::Repository).to receive(:get_installer_for).with(plugins_args.first).and_return(success)
    expect(subject.create(plugins_args)).to eq(success)
  end

  it "return nil when no strategy matches" do
    expect(LogStash::PluginManager::PackFetchStrategy::Uri).to receive(:get_installer_for).with(plugins_args.first).and_return(nil)
    expect(LogStash::PluginManager::PackFetchStrategy::Repository).to receive(:get_installer_for).with(plugins_args.first).and_return(nil)
    expect(subject.create(plugins_args)).to be_falsey
  end
end
