# encoding: utf-8
module LogStash
  class ExecutionContext
    attr_reader :pipeline, :agent

    def initialize(pipeline, agent)
      @pipeline = pipeline
      @agent = agent
    end
    
    def pipeline_id
      @pipeline.pipeline_id
    end
  end
end
