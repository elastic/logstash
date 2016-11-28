# encoding: utf-8
require "pluginmanager/pack_fetch_strategy/repository"
require "uri"
require "webmock/rspec"
require "spec_helper"

describe LogStash::PluginManager::PackFetchStrategy::Repository do
  subject { described_class }

  let(:plugin_name) { "hola-pack" }

  context "#plugin_uri" do
    it "generate an url from a name" do
      matched = URI.parse("#{subject::ELASTIC_PACK_BASE_URI}/#{plugin_name}/#{plugin_name}-#{LOGSTASH_VERSION}.#{subject::PACK_EXTENSION}")
      expect(subject.pack_uri(plugin_name)).to eq(matched)
    end
  end

  context "when the remote file exist" do
    it "is return a `RemoteInstaller`" do
      allow(LogStash::PluginManager::Utils::HttpClient).to receive(:remote_file_exist?).with(subject.pack_uri(plugin_name)).and_return(true)
      expect(subject.get_installer_for(plugin_name)).to be_kind_of(LogStash::PluginManager::PackInstaller::Remote)
    end
  end

  context "when the remote file doesnt exist" do
    it "returns false" do
      allow(LogStash::PluginManager::Utils::HttpClient).to receive(:remote_file_exist?).with(subject.pack_uri(plugin_name)).and_return(false)
      expect(subject.get_installer_for(plugin_name)).to be_falsey
    end
  end

  context "when the remote host is unreachable" do
    it "returns false and yield a debug message" do
      # To make sure we really try to connect to a failling host we have to let it through webmock
      host ="#{Time.now.to_i.to_s}-do-not-exist.com"
      WebMock.disable_net_connect!(:allow => host)
      stub_const("LogStash::PluginManager::PackFetchStrategy::Repository::ELASTIC_PACK_BASE_URI", "http://#{host}")
      expect(subject.get_installer_for(plugin_name)).to be_falsey
    end
  end
end
