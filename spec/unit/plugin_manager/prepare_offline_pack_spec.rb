# encoding: utf-8
require "spec_helper"
require "pluginmanager/main"
require "pluginmanager/prepare_offline_pack"
require "pluginmanager/offline_plugin_packager"
require "stud/temporary"
require "fileutils"

# This Test only handle the interaction with the OfflinePluginPackager class
# any test for bundler will need to be done as rats test
describe LogStash::PluginManager::PrepareOfflinePack do
  before do
    WebMock.allow_net_connect!
  end

  subject { described_class.new(cmd, {}) }

  let(:temporary_dir) { Stud::Temporary.pathname }
  let(:tmp_zip_file) { ::File.join(temporary_dir, "myspecial.zip") }
  let(:offline_plugin_packager) { double("offline_plugin_packager") }
  let(:cmd_args) { ["--output", tmp_zip_file, "logstash-input-stdin"] }
  let(:cmd) { "install" }

  before do
    FileUtils.mkdir_p(temporary_dir)

    allow(LogStash::Bundler).to receive(:invoke!).and_return(nil)
    allow(LogStash::PluginManager::OfflinePluginPackager).to receive(:package).with(anything, anything).and_return(offline_plugin_packager)
  end

  context "when not debugging" do
    before do
      @before_debug_value = ENV["DEBUG"]
      ENV["DEBUG"] = nil
    end

    after do
      ENV["DEBUG"] = @before_debug_value
    end

    it "silences paquet ui reporter" do
      expect(Paquet).to receive(:ui=).with(Paquet::SilentUI)
      subject.run(cmd_args)
    end

    context "when file target already exist" do
      before do
        FileUtils.touch(tmp_zip_file)
      end

      it "overrides the file" do
        expect(FileUtils).to receive(:rm_rf).with(tmp_zip_file)
        subject.run(cmd_args)
      end
    end

    context "when trying to use a core gem" do
      let(:exception) { LogStash::PluginManager::UnpackablePluginError }

      before do
        allow(LogStash::PluginManager::OfflinePluginPackager).to receive(:package).with(anything, anything).and_raise(exception)
      end

      it "catches the error" do
        expect(subject).to receive(:report_exception).with("Offline package", be_kind_of(exception)).and_return(nil)
        subject.run(cmd_args)
      end
    end

    context "when trying to pack a plugin that doesnt exist" do
      let(:exception) { LogStash::PluginManager::PluginNotFoundError }

      before do
        allow(LogStash::PluginManager::OfflinePluginPackager).to receive(:package).with(anything, anything).and_raise(exception)
      end

      it "catches the error" do
        expect(subject).to receive(:report_exception).with("Cannot create the offline archive", be_kind_of(exception)).and_return(nil)
        subject.run(cmd_args)
      end
    end
  end

  context "when debugging" do
    before do
      @before_debug_value = ENV["DEBUG"]
      ENV["DEBUG"] = "1"
    end

    after do
      ENV["DEBUG"] = @before_debug_value
    end

    it "doesn't silence paquet ui reporter" do
      expect(Paquet).not_to receive(:ui=).with(Paquet::SilentUI)
      subject.run(cmd_args)
    end
  end
end
