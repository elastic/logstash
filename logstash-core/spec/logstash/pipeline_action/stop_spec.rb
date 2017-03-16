# encoding: utf-8
require "spec_helper"
require_relative "../../support/helpers"
require "logstash/pipeline_action/stop"
require "logstash/pipeline"
require "logstash/instrument/null_metric"

describe LogStash::PipelineAction::Stop do
  let(:pipeline_config) { "input { generator {} } output { null {} }" }
  let(:pipeline_id) { :main }
  let(:pipeline) { mock_pipeline_from_string(pipeline_config) }
  let(:pipelines) { { :main => pipeline } }
  let(:agent) { double("agent") }

  subject { described_class.new(pipeline_id) }

  before do
    clear_data_dir
    pipeline.start
  end

  after do
    pipeline.shutdown
  end

  it "returns the pipeline_id" do
    expect(subject.pipeline_id).to eq(:main)
  end

  it "shutdown the running pipeline" do
    expect { subject.execute(agent, pipelines) }.to change(pipeline, :running?).from(true).to(false)
  end

  it "removes the pipeline from the running pipelines" do
    expect { subject.execute(agent, pipelines) }.to change { pipelines.include?(pipeline_id) }.from(true).to(false)
  end
end
