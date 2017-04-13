# encoding: utf-8
require "logstash/pipeline_action/base"
require "logstash/pipeline"
require "logstash/converge_result"
require "logstash/util/loggable"

module LogStash module PipelineAction
  class Create < Base
    include LogStash::Util::Loggable

    # We currently pass around the metric object again this
    # is needed to correctly create a pipeline, in a future
    # PR we could pass a factory to create the pipeline so we pass the logic
    # to create the pipeline instead.
    def initialize(pipeline_config, metric)
      @pipeline_config = pipeline_config
      @metric = metric
    end

    def pipeline_id
      @pipeline_config.pipeline_id
    end

    # The execute assume that the thread safety access of the pipeline
    # is managed by the caller.
    def execute(pipelines)
      pipeline = create_pipeline

      status = pipeline.start # block until the pipeline is correctly started or crashed

      if status
        pipelines[pipeline_id] = pipeline # The pipeline is successfully started we can add it to the hash
      end

      LogStash::ConvergeResult::ActionResult.create(self, status)
    end

    def create_pipeline
      LogStash::Pipeline.new(@pipeline_config.config_string, @pipeline_config.settings, @metric)
    end
  end
end end
