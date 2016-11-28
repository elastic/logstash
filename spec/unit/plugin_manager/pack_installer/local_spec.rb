# encoding: utf-8
require "pluginmanager/pack_installer/local"
require "stud/temporary"
require "fileutils"

describe LogStash::PluginManager::PackInstaller::Local do
  subject { described_class.new(local_file) }

  context "when the local file doesn't exist" do
    let(:local_file) { ::File.join(Stud::Temporary.pathname, Time.now.to_s.to_s) }

    it "raises an exception" do
      expect { subject.execute }.to raise_error(LogStash::PluginManager::FileNotFoundError)
    end
  end

  context "when the local file exist" do
    context "when the file has the wrong extension" do
      let(:local_file) { Stud::Temporary.file.path }

      it "raises a InvalidPackError" do
        expect { subject.execute }.to raise_error(LogStash::PluginManager::InvalidPackError, /Invalid format/)
      end
    end

    context "when there is an error when the zip get uncompressed" do
      let(:local_file) do
        directory = Stud::Temporary.pathname
        FileUtils.mkdir_p(directory)
        p = ::File.join(directory, "#{Time.now.to_i.to_s}.zip")
        FileUtils.touch(p)
        p
      end

      it "raises a InvalidPackError" do
        expect { subject.execute }.to raise_error(LogStash::PluginManager::InvalidPackError, /Cannot uncompress the zip/)
      end
    end

    context "when the file doesnt have plugins in it" do
      let(:local_file) { ::File.join(::File.dirname(__FILE__), "..", "..", "..", "support", "pack", "empty-pack.zip") }

      it "raise an Invalid pack" do
        expect { subject.execute }.to raise_error(LogStash::PluginManager::InvalidPackError, /The pack must contains at least one plugin/)
      end
    end

    context "when the pack is valid" do
      let(:local_file) { ::File.join(::File.dirname(__FILE__), "..", "..", "..", "support", "pack", "valid-pack.zip") }

      it "install the gems" do
        expect(::Bundler::LogstashInjector).to receive(:inject!).with(be_kind_of(Array)).and_return([])

        expect(::LogStash::PluginManager::GemInstaller).to receive(:install).with(/logstash-input-packtest/, anything)
        expect(::LogStash::PluginManager::GemInstaller).to receive(:install).with(/logstash-input-packtestdep/, anything)

        # Since the Gem::Indexer have side effect and we have more things loaded
        # I have to disable it in the tests
        mock_indexer = double("Gem::Indexer")
        allow(mock_indexer).to receive(:ui=).with(anything)
        expect(mock_indexer).to receive(:generate_index)
        expect(::Gem::Indexer).to receive(:new).with(be_kind_of(String), hash_including(:build_modern => true)).and_return(mock_indexer)

        expect { subject.execute }.not_to raise_error
      end
    end
  end
end
