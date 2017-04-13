shared_context "execution_context" do
  let(:pipeline) { double("pipeline") }
  let(:pipeline_id) { :main }
  let(:agent) { double("agent") }
  let(:execution_context) do
    ::LogStash::ExecutionContext.new(pipeline, agent)
  end
  
  before do
    allow(pipeline).to receive(:pipeline_id).and_return(pipeline_id)
    allow(pipeline).to receive(:agent).and_return(agent)
  end
end
