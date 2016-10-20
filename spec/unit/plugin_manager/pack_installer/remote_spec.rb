# encoding: utf-8
require "pluginmanager/pack_installer/remote"
require "webmock/rspec"

describe LogStash::PluginManager::PackInstaller::Remote do
  let(:url) { "http://localhost:8888/mypackage.zip" }

  subject { described_class.new(url, LogStash::PluginManager::Utils::Downloader::SilentFeedback) }

  context "when the file exist remotely" do
    let(:content) { "around the world" }

    before do
      stub_request(:get, url).to_return(
        { :status => 200,
          :body => content,
          :headers => {}}
      )
    end

    it "download the file and do a local install" do
      local_installer = double("LocalInstaller")

      expect(local_installer).to receive(:execute)
      expect(LogStash::PluginManager::PackInstaller::Local).to receive(:new).with(be_kind_of(String)).and_return(local_installer)

      subject.execute
    end
  end

  context "when the file doesn't exist remotely" do
    before do
      stub_request(:get, url).to_return({ :status => 404 })
    end

    it "raises and exception" do
      expect { subject.execute }.to raise_error(LogStash::PluginManager::FileNotFoundError, /#{url}/)
    end
  end
end
