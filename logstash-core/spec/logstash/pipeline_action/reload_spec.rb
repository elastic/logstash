# encoding: utf-8
require "spec_helper"
require_relative "../../support/helpers"
require_relative "../../support/matchers"
require "logstash/pipeline_action/reload"
require "logstash/instrument/null_metric"

describe LogStash::PipelineAction::Reload do
  let(:metric) { LogStash::Instrument::NullMetric.new(LogStash::Instrument::Collector.new) }
  let(:pipeline_id) { :main }
  let(:new_pipeline_config) { mock_pipeline_config(pipeline_id, "input { generator { id => 'new' } } output { null {} }", { "pipeline.reloadable" => true}) }
  let(:pipeline_config) { "input { generator {} } output { null {} }" }
  let(:pipeline) { mock_pipeline_from_string(pipeline_config, mock_settings("pipeline.reloadable" => true)) }
  let(:pipelines) { { pipeline_id => pipeline } }
  let(:agent) { double("agent") }

  subject { described_class.new(new_pipeline_config, metric) }

  before do
    clear_data_dir
    pipeline.start
  end

  after do
    pipelines.each { |_, pipeline| pipeline.shutdown }
  end

  it "returns the pipeline_id" do
    expect(subject.pipeline_id).to eq(pipeline_id)
  end

  context "when existing pipeline and new pipeline are both reloadable" do
    it "stop the previous pipeline" do
      expect { subject.execute(agent, pipelines) }.to change(pipeline, :running?).from(true).to(false)
    end

    it "start the new pipeline" do
      subject.execute(agent, pipelines)
      expect(pipelines[pipeline_id].running?).to be_truthy
    end

    it "run the new pipeline code" do
      subject.execute(agent, pipelines)
      expect(pipelines[pipeline_id].config_hash).to eq(new_pipeline_config.config_hash)
    end
  end

  context "when the existing pipeline is not reloadable" do
    before do
      allow(pipeline).to receive(:reloadable?).and_return(false)
    end

    it "cannot successfully execute the action" do
      expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
    end
  end

  context "when the new pipeline is not reloadable" do
    let(:new_pipeline_config) { mock_pipeline_config(pipeline_id, "input { generator { id => 'new' } } output { null {} }", { "pipeline.reloadable" => false}) }

    it "cannot successfully execute the action" do
      expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
    end
  end

  context "when the new pipeline has syntax errors" do
    let(:new_pipeline_config) { mock_pipeline_config(pipeline_id, "input generator { id => 'new' } } output { null {} }", { "pipeline.reloadable" => false}) }

    it "cannot successfully execute the action" do
      expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
    end
  end

  context "when there is an error in the register" do
    before do
      allow_any_instance_of(LogStash::Inputs::Generator).to receive(:register).and_raise("Bad value")
    end

    it "cannot successfully execute the action" do
      expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
    end
  end
end
