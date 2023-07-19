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

require 'time'

shared_context "execution_context" do
  let(:pipeline) { double("pipeline") }
  let(:pipeline_id) { :main }
  let(:agent) { double("agent") }
  let(:plugin_id) { :plugin_id }
  let(:plugin_type) { :plugin_type }
  let(:dlq_writer) { double("dlq_writer") }
  let(:execution_context_factory) { ::LogStash::Plugins::ExecutionContextFactory.new(agent, pipeline, dlq_writer) }
  let(:execution_context) do
    execution_context_factory.create(plugin_id, plugin_type)
  end

  before do
    allow(pipeline).to receive(:pipeline_id).and_return(pipeline_id)
    allow(pipeline).to receive(:agent).and_return(agent)
  end
end

shared_context "api setup" do |settings_overrides = {}|
  ##
  # blocks until the condition returns true, or the limit has passed
  # @return [true] if the condition was met
  # @return [false] if the condition was NOT met
  def block_until(limit_seconds, &condition)
    deadline = Time.now + limit_seconds
    loop.with_index do |_, try|
      break if Time.now >= deadline
      return true if condition.call

      next_sleep = [(2.0**(try)) / 10, 2, deadline - Time.now].min
      Kernel::sleep(next_sleep) unless next_sleep <= 0
    end
    # one last try
    condition.call
  end

  before :all do
    clear_data_dir
    settings = mock_settings({"config.reload.automatic" => true}.merge(settings_overrides))
    config_source = make_config_source(settings)
    config_source.add_pipeline('main', "input { generator {id => 'api-generator-pipeline' count => 100 } } output { dummyoutput {} }")

    @agent = make_test_agent(settings, config_source)
    @agent_execution_task = Stud::Task.new { @agent.execute }
    block_until(30) { @agent.loaded_pipelines.keys.include?(:main) } or fail('main pipeline did not come up')

    config_source.add_pipeline('main', "input { generator { id => '123' } } output { null {} }")
    config_source.add_pipeline('secondary', "input { generator { id => '123' } } output { null {} }")
    block_until(30) { ([:main, :secondary] - @agent.running_pipelines.keys).empty? } or fail('pipelines did not come up')
  end

  after :all do
    @agent_execution_task.stop!
    @agent_execution_task.wait
    @agent.shutdown
  end

  include Rack::Test::Methods

  def app()
    described_class.new(nil, @agent)
  end
end
