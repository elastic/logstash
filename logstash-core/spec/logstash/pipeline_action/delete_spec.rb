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
require "logstash/pipeline_action/delete"
require "logstash/inputs/generator"


describe LogStash::PipelineAction::Delete do
  let(:pipeline_config) { "input { dummyblockinginput {} } output { null {} }" }
  let(:pipeline_id) { :main }
  let(:pipeline) { mock_java_pipeline_from_string(pipeline_config) }
  let(:pipelines) do
    LogStash::PipelinesRegistry.new.tap do |chm|
      chm.create_pipeline(pipeline_id, pipeline) { true }
    end
  end
  let(:agent) { double("agent") }

  subject { described_class.new(pipeline_id) }

  before do
    clear_data_dir
    allow(agent).to receive(:health_observer).and_return(double("HealthObserver").as_null_object)
    pipeline.start
  end

  after do
    pipeline.shutdown
  end

  it "returns the pipeline_id" do
    expect(subject.pipeline_id).to eq(:main)
  end

  context "when the pipeline is still running" do

    it 'fails to delete the pipeline' do
      action_result = subject.execute(agent, pipelines)
      expect(action_result).to_not be_successful

      expect(pipelines.get_pipeline(pipeline_id)).to_not be_nil
    end
  end

  context "when the pipeline has completed" do
    let(:pipeline_config) { "input { generator { count => 1 } } output { null {} }"}

    before(:each) do
      sleep(0.1) until pipelines.non_running_pipelines.keys.include?(pipeline_id)
    end

    it 'deletes the pipeline' do
      action_result = subject.execute(agent, pipelines)
      expect(action_result).to be_successful

      expect(pipelines.get_pipeline(pipeline_id)).to be_nil
      expect(agent.health_observer).to have_received(:detach_pipeline_indicator).with(pipeline_id)
    end
  end
end