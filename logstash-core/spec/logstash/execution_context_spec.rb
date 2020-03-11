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
