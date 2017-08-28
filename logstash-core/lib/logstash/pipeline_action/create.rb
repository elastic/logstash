# encoding: utf-8
require "logstash/pipeline_action/base"
require "logstash/pipeline"
require "logstash/converge_result"
require "logstash/util/loggable"

module LogStash module PipelineAction
  class Create < Base
    include LogStash::Util::Loggable


    def initialize(pipeline_config)
      @pipeline_config = pipeline_config
    end

    def pipeline_id
      @pipeline_config.pipeline_id
    end

    # Make sure we execution system pipeline like the monitoring
    # before any user defined pipelines, system pipeline register hooks into the system that will be
    # triggered by the user defined pipeline.
    def execution_priority
      default_priority = super
      @pipeline_config.system? ? default_priority * -1 : default_priority
    end

    # The execute assume that the thread safety access of the pipeline
    # is managed by the caller.
    def execute(agent, pipelines)
      pipeline = LogStash::Pipeline.new(@pipeline_config, agent)
      
      status = pipeline.start # block until the pipeline is correctly started or crashed

      if status
        pipelines[pipeline_id] = pipeline # The pipeline is successfully started we can add it to the hash
      end

      LogStash::ConvergeResult::ActionResult.create(self, status)
    end
  end
end end
