# encoding: utf-8
require "spec_helper"
require_relative "../../support/helpers"
require "logstash/pipeline_action/create"
require "logstash/instrument/null_metric"
require "logstash/inputs/generator"

describe LogStash::PipelineAction::Create do
  let(:metric) { LogStash::Instrument::NullMetric.new(LogStash::Instrument::Collector.new) }
  let(:pipeline_config) { mock_pipeline_config(:main, "input { generator { id => '123' } } output { null {} }") }
  let(:pipelines) {  Hash.new }

  before do
    clear_data_dir
  end

  subject { described_class.new(pipeline_config, metric) }

  after do
    pipelines.each { |_, pipeline| pipeline.shutdown }
  end

  it "returns the pipeline_id" do
    expect(subject.pipeline_id).to eq(:main)
  end


  context "when we have really short lived pipeline" do
    let(:pipeline_config) { mock_pipeline_config(:main, "input { generator { count => 1 } } output { null {} }") }

    it "returns a successful execution status" do
      expect(subject.execute(pipelines)).to be_truthy
    end
  end

  context "when the pipeline succesfully start" do
    it "adds the pipeline to the current pipelines" do
      expect { subject.execute(pipelines) }.to change(pipelines, :size).by(1)
    end

    it "starts the pipeline" do
      subject.execute(pipelines)
      expect(pipelines[:main].running?).to be_truthy
    end

    it "returns a successful execution status" do
      expect(subject.execute(pipelines)).to be_truthy
    end
  end

  context  "when the pipeline doesn't start" do
    context "with a syntax error" do
      let(:pipeline_config) { mock_pipeline_config(:main, "input { generator { id => '123' } } output { stdout ") } # bad syntax

      it "raises the exception upstream" do
        expect { subject.execute(pipelines) }.to raise_error
      end
    end

    context "with an error raised during `#register`" do
      let(:pipeline_config) { mock_pipeline_config(:main, "input { generator { id => '123' } } filter { ruby { init => '1/0' code => '1+2' } } output { null {} }") }

      it "returns false" do
        expect(subject.execute(pipelines)).not_to be_a_successful_action
      end
    end
  end
end
