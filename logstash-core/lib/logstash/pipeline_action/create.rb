# encoding: utf-8
require "logstash/pipeline_action/base"
require "logstash/pipeline"
require "logstash/java_pipeline"
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
      pipeline =
        if @pipeline_config.settings.get_value("pipeline.java_execution")
          LogStash::JavaPipeline.new(@pipeline_config, @metric, agent)
        else
          LogStash::Pipeline.new(@pipeline_config, @metric, agent)
        end

      status = pipeline.start # block until the pipeline is correctly started or crashed

      if status
        pipelines[pipeline_id] = pipeline # The pipeline is successfully started we can add it to the hash
      end

      LogStash::ConvergeResult::ActionResult.create(self, status)
    end
  end
end end
