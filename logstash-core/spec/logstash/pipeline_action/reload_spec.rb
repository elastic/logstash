# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "spec_helper"
require_relative "../../support/helpers"
require_relative "../../support/matchers"
require "logstash/pipelines_registry"
require "logstash/pipeline_action/reload"

describe LogStash::PipelineAction::Reload do
  let(:metric) { LogStash::Instrument::NullMetric.new(LogStash::Instrument::Collector.new) }
  let(:pipeline_id) { :main }
  let(:new_pipeline_config) { mock_pipeline_config(pipeline_id, "input { dummyblockinginput { id => 'new' } } output { null {} }", { "pipeline.reloadable" => true}) }
  let(:pipeline_config) { "input { dummyblockinginput {} } output { null {} }" }
  let(:pipeline) { mock_java_pipeline_from_string(pipeline_config, mock_settings("pipeline.reloadable" => true)) }
  let(:pipelines) { r = LogStash::PipelinesRegistry.new; r.create_pipeline(pipeline_id, pipeline) { true }; r }
  let(:agent) { double("agent") }

  subject { described_class.new(new_pipeline_config, metric) }

  before do
    clear_data_dir
    pipeline.start
  end

  after do
    pipelines.running_pipelines do |_, pipeline|
      pipeline.shutdown
      pipeline.thread.join
    end
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
      expect(pipelines.get_pipeline(pipeline_id).running?).to be_truthy
    end

    it "run the new pipeline code" do
      subject.execute(agent, pipelines)
      expect(pipelines.get_pipeline(pipeline_id).config_hash).to eq(new_pipeline_config.config_hash)
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
    let(:new_pipeline_config) { mock_pipeline_config(pipeline_id, "input { dummyblockinginput { id => 'new' } } output { null {} }", { "pipeline.reloadable" => false}) }

    it "cannot successfully execute the action" do
      expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
    end
  end

  context "when the new pipeline has syntax errors" do
    let(:new_pipeline_config) { mock_pipeline_config(pipeline_id, "input dummyblockinginput { id => 'new' } } output { null {} }", { "pipeline.reloadable" => false}) }

    it "cannot successfully execute the action" do
      expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
    end
  end

  context "when there is an error in the register" do
    before do
      allow_any_instance_of(LogStash::Inputs::DummyBlockingInput).to receive(:register).and_raise("Bad value")
    end

    it "cannot successfully execute the action" do
      expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
    end
  end
end
