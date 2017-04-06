# encoding: utf-8
require "spec_helper"
require "logstash/execution_context"

describe LogStash::ExecutionContext do
  let(:pipeline_id) { :main }

  subject { described_class.new(pipeline_id) }

  it "returns the `pipeline_id`" do
    expect(subject.pipeline_id).to eq(pipeline_id)
  end
end
