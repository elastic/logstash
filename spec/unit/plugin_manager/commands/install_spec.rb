# encoding: utf-8
require "spec_helper"
require "clamp"
require "pluginmanager/commands/install_command"
require "uri"
require 'webmock/rspec'

describe LogStash::PluginManager::InstallCommand do

  subject { described_class.new("install") }

  let(:server)     { "https://download.elastic.co/" }
  let(:user_agent) { LogStash::PluginManager::Sources::HTTP::USER_AGENT }

  describe "#packs" do

    let(:jdbc_source)   { LogStash::PluginManager::Sources::HTTP.new("https://download.elastic.co/jdbc_pack-3.0.0.dev.zip") }
    let(:syslog_source) { LogStash::PluginManager::Sources::HTTP.new("https://download.elastic.co/syslog_pack-3.0.0.dev.zip") }


    it "select plugins to be installed" do
      files = [ "/foo/bar/plugin.gem", "/foo/bar/bar-2.0.gem" ]
      expect(Dir).to receive(:glob).with(File.join("/foo/bar", "*.gem")).and_return(files)
      expect(subject.select_plugins("/foo/bar")).to eq(["plugin", "bar"])
    end

    context "#find packs" do
      let(:syslog_pack_url) { "https://download.elastic.co:443/syslog_pack-3.0.0.dev.zip" }

      it "finds the packs to be installed" do
        stub_request(:head, syslog_pack_url ).to_return(:status => 200)

        args    = [ "https://download.elastic.co/jdbc_pack-3.0.0.dev.zip", "syslog_pack-3.0.0.dev", "logstash-input-foo" ]
        sources = subject.find_packs(args).map { |source| source.to_s }
        uris    = [ "https://download.elastic.co/jdbc_pack-3.0.0.dev.zip", "https://download.elastic.co/syslog_pack-3.0.0.dev.zip" ]
        expect(sources).to eq(uris)
      end

      it "uses a descriptive user agent" do
        stub_request(:head, syslog_pack_url).
          with(:headers => {'User-Agent'=>"#{user_agent}"}).to_return(:status => 200)
        subject.find_packs([ "syslog_pack-3.0.0.dev" ])
      end
    end

    context "#fetch packs" do

      it "yield the sources to process the extractions as requested" do
        args = [ jdbc_source, syslog_source ]

        yield_values = [
          [jdbc_source, kind_of(String)],
          [syslog_source, kind_of(String)]
        ]

        expect { |b|
          subject.fetch_and_copy_packs(args, &b)
        }.to yield_successive_args(*yield_values)
      end

      it "uses a descriptive user agent" do
        stub_request(:get, "https://download.elastic.co:443/syslog_pack-3.0.0.dev.zip").
          with(:headers => {'User-Agent'=>"#{user_agent}"}).to_return(:status => 200)
        subject.fetch_pack(syslog_source, Dir.tmpdir)
      end

    end
  end
end
