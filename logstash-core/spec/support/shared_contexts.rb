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
