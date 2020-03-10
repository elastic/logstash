# encoding: utf-8
require "spec_helper"

describe LogStash::ExecutionContext do
  let(:pipeline) { double("pipeline") }
  let(:pipeline_id) { :main }
  let(:agent) { double("agent") }
  let(:plugin_id) { "plugin_id" }
  let(:plugin_type) { "plugin_type" }
  let(:dlq_writer) { LogStash::Util::DummyDeadLetterQueueWriter.new }

  before do
    allow(pipeline).to receive(:agent).and_return(agent)
    allow(pipeline).to receive(:pipeline_id).and_return(pipeline_id)
  end

  subject { described_class.new(pipeline, agent, plugin_id, plugin_type, dlq_writer) }

  it "returns the `pipeline_id`" do
    expect(subject.pipeline_id).to eq(pipeline_id)
  end

  it "returns the pipeline" do
    expect(subject.pipeline).to eq(pipeline)
  end

  it "returns the agent" do
    expect(subject.agent).to eq(agent)
  end

  it "returns the plugin-specific dlq writer" do
    expect(subject.dlq_writer.plugin_type).to eq(plugin_type)
    expect(subject.dlq_writer.plugin_id).to eq(plugin_id)
    expect(subject.dlq_writer.inner_writer).to eq(dlq_writer)
  end
end
