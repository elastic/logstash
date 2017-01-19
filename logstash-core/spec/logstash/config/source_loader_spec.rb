# encoding: utf-8
require "logstash/config/source_loader"
require "logstash/config/source/base"
require_relative "../../support/helpers"

class DummyLoader < LogStash::Config::Source::Base
  def pipeline_configs
    [self.class]
  end

  def self.match?(settings)
    settings.get("path.config") =~ /dummy/
  end
end

class AnotherDummyLoader < LogStash::Config::Source::Base
  def pipeline_configs
    [self.class]
  end

  def self.match?(settings)
    settings.get("path.config") =~ /another/
  end
end

describe LogStash::Config::SourceLoader do
  subject { described_class.new }

  it "default to local source" do
    loaders = []

    subject.source_loaders { |loader| loaders << loader }

    expect(loaders.size).to eq(1)
    expect(loaders).to include(LogStash::Config::Source::Local)
  end

  it "allows to override the available source loaders" do
    subject.configure_sources(DummyLoader)
    loaders = []
    subject.source_loaders { |loader| loaders << loader }

    expect(loaders.size).to eq(1)
    expect(loaders).to include(DummyLoader)
  end

  it "allows to add a new source" do
    loaders = []
    subject.add_source(DummyLoader)
    subject.source_loaders { |loader| loaders << loader }

    expect(loaders.size).to eq(2)
    expect(loaders).to include(DummyLoader, LogStash::Config::Source::Local)
  end

  context "when no source match" do
    let(:settings) { mock_settings("path.config" => "make it not match") } # match both regex

    it "return the loaders with the matched sources" do
      subject.configure_sources([DummyLoader, AnotherDummyLoader])

      expect { config_loader = subject.create(settings) }.to raise_error
    end
  end

  context "when source loader match" do
    context "when multiple match" do
      let(:settings) { mock_settings("path.config" => "another dummy") } # match both regex

      it "return the loaders with the matched sources" do
        subject.configure_sources([DummyLoader, AnotherDummyLoader])

        config_loader = subject.create(settings)

        expect(config_loader.pipeline_configs.size).to eq(2)
        expect(config_loader.pipeline_configs).to include(DummyLoader, AnotherDummyLoader)
      end
    end

    context "when multiple match" do
      let(:settings) { mock_settings("path.config" => "another") } # match both regex

      it "return the loaders with the matched sources" do
        subject.configure_sources([DummyLoader, AnotherDummyLoader])

        config_loader = subject.create(settings)

        expect(config_loader.pipeline_configs.size).to eq(1)
        expect(config_loader.pipeline_configs).to include(AnotherDummyLoader)
      end
    end
  end
end
