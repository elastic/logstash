# encoding: utf-8
require "pluginmanager/pack_fetch_strategy/uri"
require "stud/temporary"

describe LogStash::PluginManager::PackFetchStrategy::Uri do
  subject { described_class }
  context "when we dont have URI path" do
    let(:plugin_path) { "logstash-input-elasticsearch" }

    it "doesnt return an installer" do
      expect(subject.get_installer_for(plugin_path)).to be_falsey
    end
  end

  context "we have another URI scheme than file or http" do
    let(:plugin_path) { "ftp://localhost:8888/my-pack.zip" }

    it "doesnt return an installer" do
      expect(subject.get_installer_for(plugin_path)).to be_falsey
    end
  end

  context "we have an invalid URI scheme" do
    let(:plugin_path) { "inv://localhost:8888/my-pack.zip" }

    it "doesnt return an installer" do
      expect(subject.get_installer_for(plugin_path)).to be_falsey
    end
  end

  context "when we have a local path" do
    let(:temporary_file) do
      f = Stud::Temporary.file
      f.write("hola")
      f.path
    end

    let(:plugin_path) { "file://#{temporary_file}" }

    it "returns a `LocalInstaller`" do
      expect(subject.get_installer_for(plugin_path)).to be_kind_of(LogStash::PluginManager::PackInstaller::Local)
    end
  end

  context "when we have a remote path" do
    let(:plugin_path) { "http://localhost:8888/my-pack.zip" }

    it "returns a remote installer" do
      expect(subject.get_installer_for(plugin_path)).to be_kind_of(LogStash::PluginManager::PackInstaller::Remote)
    end
  end
end
