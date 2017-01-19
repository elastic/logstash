# encoding: utf-8
require "logstash/config/pipeline_config"
require "logstash/config/config_part"
require "logstash/config/source/local"

describe LogStash::Config::PipelineConfig do
  let(:source) { LogStash::Config::Source::Local }
  let(:pipeline_id) { :main }
  let(:ordered_config_parts) do
    [
      LogStash::Config::ConfigPart.new(LogStash::Config::Source::Local::ConfigPathLoader, "/tmp/1", "input { generator1 }"),
      LogStash::Config::ConfigPart.new(LogStash::Config::Source::Local::ConfigPathLoader, "/tmp/2", "input { generator2 }"),
      LogStash::Config::ConfigPart.new(LogStash::Config::Source::Local::ConfigPathLoader, "/tmp/3", "input { generator3 }"),
      LogStash::Config::ConfigPart.new(LogStash::Config::Source::Local::ConfigPathLoader, "/tmp/4", "input { generator4 }"),
      LogStash::Config::ConfigPart.new(LogStash::Config::Source::Local::ConfigPathLoader, "/tmp/5", "input { generator5 }"),
      LogStash::Config::ConfigPart.new(LogStash::Config::Source::Local::ConfigPathLoader, "/tmp/6", "input { generator6 }"),
      LogStash::Config::ConfigPart.new(LogStash::Config::Source::Local::ConfigStringLoader, "config_string", "input { generator1 }"),
    ]
  end

  let(:unordered_config_parts) { ordered_config_parts.shuffle }
  let(:settings) { LogStash::SETTINGS }

  subject { described_class.new(source, pipeline_id, unordered_config_parts, settings) }

  it "returns the source" do
    expect(subject.source).to eq(source)
  end

  it "returns the pipeline id" do
    expect(subject.pipeline_id).to eq(pipeline_id)
  end

  it "returns the sorted config parts" do
    expect(subject.config_parts).to eq(ordered_config_parts)
  end

  it "returns the config_hash" do
    expect(subject.config_hash).not_to be_nil
  end

  it "does object equality on config_hash and pipeline_id" do
    another_exact_pipeline = described_class.new(source, pipeline_id, ordered_config_parts, settings)
    expect(subject).to eq(another_exact_pipeline)

    not_matching_pipeline = described_class.new(source, pipeline_id, [], settings)
    expect(subject).not_to eq(not_matching_pipeline)

    not_same_pipeline_id = described_class.new(source, :another_pipeline, unordered_config_parts, settings)
    expect(subject).not_to eq(not_same_pipeline_id)
  end
end
