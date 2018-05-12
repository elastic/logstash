# encoding: utf-8
require "logstash/config/pipeline_config"
require "logstash/config/source/local"

describe LogStash::Config::PipelineConfig do
  let(:source) { LogStash::Config::Source::Local }
  let(:pipeline_id) { :main }
  let(:ordered_config_parts) do
    [
      org.logstash.common.SourceWithMetadata.new("file", "/tmp/1", 0, 0, "input { generator1 }"),
      org.logstash.common.SourceWithMetadata.new("file", "/tmp/2", 0, 0,  "input { generator2 }"),
      org.logstash.common.SourceWithMetadata.new("file", "/tmp/3", 0, 0, "input { generator3 }"),
      org.logstash.common.SourceWithMetadata.new("file", "/tmp/4", 0, 0, "input { generator4 }"),
      org.logstash.common.SourceWithMetadata.new("file", "/tmp/5", 0, 0, "input { generator5 }"),
      org.logstash.common.SourceWithMetadata.new("file", "/tmp/6", 0, 0, "input { generator6 }"),
      org.logstash.common.SourceWithMetadata.new("string", "config_string", 0, 0, "input { generator1 }"),
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

  it "returns the merged `ConfigPart#config_string`" do
    expect(subject.config_string).to eq(ordered_config_parts.collect(&:text).join("\n"))
  end

  it "records when the config was read" do
    expect(subject.read_at).to be <= Time.now
  end

  it "does object equality on config_hash and pipeline_id" do
    another_exact_pipeline = described_class.new(source, pipeline_id, ordered_config_parts, settings)
    expect(subject).to eq(another_exact_pipeline)

    not_matching_pipeline = described_class.new(source, pipeline_id, [], settings)
    expect(subject).not_to eq(not_matching_pipeline)

    not_same_pipeline_id = described_class.new(source, :another_pipeline, unordered_config_parts, settings)
    expect(subject).not_to eq(not_same_pipeline_id)
  end

  describe "#system?" do
    context "when the pipeline is a system pipeline" do
      let(:settings) { mock_settings({ "pipeline.system" => true })}

      it "returns true if the pipeline is a system pipeline" do
        expect(subject.system?).to be_truthy
      end
    end

    context "when is not a system pipeline" do
      it "returns false if the pipeline is not a system pipeline" do
        expect(subject.system?).to be_falsey
      end
    end
  end
end
