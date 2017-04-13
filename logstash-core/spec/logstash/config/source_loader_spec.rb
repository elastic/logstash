# encoding: utf-8
require "logstash/config/source_loader"
require "logstash/config/source/base"
require_relative "../../support/helpers"

class DummySource < LogStash::Config::Source::Base
  def pipeline_configs
    [self.class]
  end

  def match?
    @settings.get("path.config") =~ /dummy/
  end
end

class AnotherDummySource < LogStash::Config::Source::Base
  def pipeline_configs
    [self.class]
  end

  def match?
    @settings.get("path.config") =~ /another/
  end
end

class FailingSource < LogStash::Config::Source::Base
  def pipeline_configs
    raise "Something went wrong"
  end

  def match?
    @settings.get("path.config") =~ /fail/
  end
end

describe LogStash::Config::SourceLoader do
  subject { described_class.new }

  it "default to local source" do
    expect(subject.sources.size).to eq(0)
  end

  it "allows to override the available source loaders" do
    subject.configure_sources(DummySource)
    expect(subject.sources.size).to eq(1)
    expect(subject.sources).to include(DummySource)
  end

  it "allows to add a new sources" do
    subject.add_source(DummySource)
    subject.add_source(LogStash::Config::Source::Local)

    expect(subject.sources.size).to eq(2)
    expect(subject.sources).to include(DummySource, LogStash::Config::Source::Local)
  end

  context "when no source match" do
    let(:settings) { mock_settings("path.config" => "make it not match") } # match both regex

    it "raises an exception" do
      subject.configure_sources([DummySource.new(settings), AnotherDummySource.new(settings)])

      expect { subject.fetch }.to raise_error
    end
  end

  context "when source loader match" do
    context "when an happen in the source" do
      let(:settings) { mock_settings("path.config" => "dummy fail") }

      it "wraps the error in a failed result" do
        subject.configure_sources([DummySource.new(settings), FailingSource.new(settings)])

        result = subject.fetch

        expect(result.success?).to be_falsey
        expect(result.error).not_to be_nil
      end
    end

    context "when multiple match" do
      let(:settings) { mock_settings("path.config" => "another dummy") } # match both regex

      it "return the loaders with the matched sources" do
        subject.configure_sources([DummySource.new(settings), AnotherDummySource.new(settings)])

        result = subject.fetch

        expect(result.success?).to be_truthy
        expect(result.response.size).to eq(2)
        expect(result.response).to include(DummySource, AnotherDummySource)
      end
    end

    context "when multiple match" do
      let(:settings) { mock_settings("path.config" => "another") } # match both regex

      it "return the loaders with the matched sources" do
        subject.configure_sources([DummySource.new(settings), AnotherDummySource.new(settings)])

        result = subject.fetch

        expect(result.success?).to be_truthy
        expect(result.response.size).to eq(1)
        expect(result.response).to include(AnotherDummySource)
      end
    end
  end
end
