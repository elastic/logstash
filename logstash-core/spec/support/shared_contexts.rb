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
    pipeline_config = mock_pipeline_config(:main, "input { generator { id => '123' } } output { null {} }")
    pipeline_creator =  LogStash::PipelineAction::Create.new(pipeline_config, @agent.metric)
    @pipelines = java.util.concurrent.ConcurrentHashMap.new
    expect(pipeline_creator.execute(@agent, @pipelines)).to be_truthy
  end

  after :all do
    @agent.shutdown
    @pipelines.each do |_, pipeline|
      pipeline.shutdown
      pipeline.thread.join
    end
  end

  include Rack::Test::Methods

  def app()
    described_class.new(nil, @agent)
  end
end