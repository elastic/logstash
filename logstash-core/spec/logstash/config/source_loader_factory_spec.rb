# encoding: utf-8
require "logstash/config/source_loader_factory"
require "logstash/environment"
require "logstash/settings"
require_relative "../../support/helpers"
require "spec_helper"

describe LogStash::Config::SourceLoaderFactory do
  subject { described_class.new(settings) }

  context "using `-e` (Config String)" do
    let(:config_string) { "input { generator{} output {}" }

    let(:settings) do
      mock_settings("config.string" => config_string)
    end

    it "returns a `ConfigString` loader" do
      expect(subject.create).to be_kind_of(LogStash::Config::SourceLoader::ConfigString)
    end
  end

  context "using `-f` (path)" do
    context "when its a local file" do
      let(:config_file) { "temporary-file" }

      let(:settings) do
        mock_settings("path.config" => config_file)
      end

      it "returns a `LocalFile` loader" do
        expect(subject.create).to be_kind_of(LogStash::Config::SourceLoader::LocalFile)
      end
    end

    context "when its a remote file" do
      let(:remote_file) { "http://test.dev/temporary-file.conf" }

      let(:settings) do
        mock_settings("path.config" => remote_file)
      end

      it "returns a `RemoteFile` loader" do
        expect(subject.create).to be_kind_of(LogStash::Config::SourceLoader::RemoteFile)
      end
    end
  end
end
