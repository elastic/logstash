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
require "logstash/pipeline_action/create"
require "logstash/inputs/generator"

describe LogStash::PipelineAction::Create do
  let(:metric) { LogStash::Instrument::NullMetric.new(LogStash::Instrument::Collector.new) }
  let(:pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput { id => '123' } } output { null {} }") }
  let(:pipelines) { LogStash::PipelinesRegistry.new }
  let(:agent) { double("agent") }

  before do
    clear_data_dir
  end

  subject { described_class.new(pipeline_config, metric) }

  after do
    pipelines.running_pipelines do |_, pipeline|
      pipeline.shutdown
      pipeline.thread.join
    end
  end

  it "returns the pipeline_id" do
    expect(subject.pipeline_id).to eq(:main)
  end

  context "when we have really short lived pipeline" do
    let(:pipeline_config) { mock_pipeline_config(:main, "input { generator { count => 1 } } output { null {} }") }

    it "returns a successful execution status" do
      expect(subject.execute(agent, pipelines)).to be_truthy
    end
  end

  context "when the pipeline successfully start" do
    it "adds the pipeline to the current pipelines" do
      expect { subject.execute(agent, pipelines) }.to change(pipelines, :size).by(1)
    end

    it "starts the pipeline" do
      subject.execute(agent, pipelines)
      expect(pipelines.get_pipeline(:main).running?).to be_truthy
    end

    it "returns a successful execution status" do
      expect(subject.execute(agent, pipelines)).to be_truthy
    end
  end

  context "when the pipeline doesn't start" do
    context "with a syntax error" do
      let(:pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput { id => '123' } } output { stdout ") } # bad syntax

      it "raises the exception upstream" do
        expect { subject.execute(agent, pipelines) }.to raise_error
      end
    end

    context "with an error raised during `#register`" do
      let(:pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput { id => '123' } } filter { ruby { init => '1/0' code => '1+2' } } output { null {} }") }

      it "returns false" do
        expect(subject.execute(agent, pipelines)).not_to be_a_successful_action
      end
    end
  end

  context "when sorting create action" do
    let(:pipeline_config) { mock_pipeline_config(:main, "input { dummyblockinginput { id => '123' } } output { null {} }") }
    let(:system_pipeline_config) { mock_pipeline_config(:main_2, "input { dummyblockinginput { id => '123' } } output { null {} }", { "pipeline.system" => true }) }

    it "should give higher priority to system pipeline" do
      action_user_pipeline = described_class.new(pipeline_config, metric)
      action_system_pipeline = described_class.new(system_pipeline_config, metric)

      sorted = [action_user_pipeline, action_system_pipeline].sort
      expect(sorted).to eq([action_system_pipeline, action_user_pipeline])
    end
  end
end
