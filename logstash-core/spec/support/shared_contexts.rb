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

shared_context "execution_context" do
  let(:pipeline) { double("pipeline") }
  let(:pipeline_id) { :main }
  let(:agent) { double("agent") }
  let(:plugin_id) { :plugin_id }
  let(:plugin_type) { :plugin_type }
  let(:dlq_writer) { double("dlq_writer") }
  let(:execution_context) do
    ::LogStash::ExecutionContext.new(pipeline, agent, plugin_id, plugin_type, dlq_writer)
  end

  before do
    allow(pipeline).to receive(:pipeline_id).and_return(pipeline_id)
    allow(pipeline).to receive(:agent).and_return(agent)
  end
end

shared_context "api setup" do
  before :all do
    clear_data_dir
    settings = mock_settings
    config_string = "input { generator {id => 'api-generator-pipeline' count => 100 } } output { dummyoutput {} }"
    settings.set("config.string", config_string)
    settings.set("config.reload.automatic", false)
    @agent = make_test_agent(settings)
    @agent.execute
    @pipelines_registry = LogStash::PipelinesRegistry.new
    pipeline_config = mock_pipeline_config(:main, "input { generator { id => '123' } } output { null {} }")
    pipeline_creator =  LogStash::PipelineAction::Create.new(pipeline_config, @agent.metric)
    expect(pipeline_creator.execute(@agent, @pipelines_registry)).to be_truthy
    pipeline_config = mock_pipeline_config(:secondary, "input { generator { id => '123' } } output { null {} }")
    pipeline_creator =  LogStash::PipelineAction::Create.new(pipeline_config, @agent.metric)
    expect(pipeline_creator.execute(@agent, @pipelines_registry)).to be_truthy
  end

  after :all do
    @pipelines_registry.running_pipelines.each do |_, pipeline|
      pipeline.shutdown
      pipeline.thread.join
    end
    @agent.shutdown
  end

  include Rack::Test::Methods

  def app()
    described_class.new(nil, @agent)
  end
end