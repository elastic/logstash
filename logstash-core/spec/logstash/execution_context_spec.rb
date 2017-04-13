# encoding: utf-8
require "spec_helper"
require "logstash/execution_context"

describe LogStash::ExecutionContext do
  let(:pipeline) { double("pipeline") }
  let(:pipeline_id) { :main }
  let(:agent) { double("agent") }
  
  before do
    allow(pipeline).to receive(:agent).and_return(agent)
    allow(pipeline).to receive(:pipeline_id).and_return(pipeline_id)
  end

  subject { described_class.new(pipeline, agent) }

  it "returns the `pipeline_id`" do
    expect(subject.pipeline_id).to eq(pipeline_id)
  end
  
  it "returns the pipeline" do
    expect(subject.pipeline).to eq(pipeline)
  end
  
  it "returns the agent" do
    expect(subject.agent).to eq(agent)
  end
end
