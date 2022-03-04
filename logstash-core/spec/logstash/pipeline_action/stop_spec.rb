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
require "logstash/pipelines_registry"
require "logstash/pipeline_action/stop"

describe LogStash::PipelineAction::Stop do
  let(:pipeline_config) { "input { dummyblockinginput {} } output { null {} }" }
  let(:pipeline_id) { :main }
  let(:pipeline) { mock_java_pipeline_from_string(pipeline_config) }
  let(:pipelines) { chm = LogStash::PipelinesRegistry.new; chm.create_pipeline(pipeline_id, pipeline) { true }; chm }
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
    expect { subject.execute(agent, pipelines) }.to change { pipelines.running_pipelines.keys }.from([:main]).to([])
  end
end
