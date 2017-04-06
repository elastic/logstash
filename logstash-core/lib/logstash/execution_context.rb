# encoding: utf-8
module LogStash
  class ExecutionContext
    attr_reader :pipeline_id

    def initialize(pipeline_id)
      @pipeline_id = pipeline_id
    end
  end
end
