# encoding: utf-8
require "logstash/pipeline_action/base"
require "logstash/pipeline_action/create"
require "logstash/pipeline_action/stop"
require "logstash/errors"
require "logstash/util/loggable"
require "logstash/converge_result"

module LogStash module PipelineAction
  class Reload < Base
    include LogStash::Util::Loggable

    def initialize(pipeline_config, metric)
      @pipeline_config = pipeline_config
      @metric = metric
    end

    def pipeline_id
      @pipeline_config.pipeline_id
    end

    def execute(agent, pipelines)
      old_pipeline = pipelines[pipeline_id]

      if !old_pipeline.reloadable?
        return LogStash::ConvergeResult::FailedAction.new("Cannot reload pipeline, because the existing pipeline is not reloadable")
      end

      begin
        pipeline_validator =
          if @pipeline_config.settings.get_value("pipeline.java_execution")
            LogStash::JavaBasePipeline.new(@pipeline_config)
          else
            LogStash::BasePipeline.new(@pipeline_config)
          end
      rescue => e
        return LogStash::ConvergeResult::FailedAction.from_exception(e)
      end

      if !pipeline_validator.reloadable?
        return LogStash::ConvergeResult::FailedAction.new("Cannot reload pipeline, because the new pipeline is not reloadable")
      end

      logger.info("Reloading pipeline", "pipeline.id" => pipeline_id)
      status = Stop.new(pipeline_id).execute(agent, pipelines)

      if status
        return Create.new(@pipeline_config, @metric).execute(agent, pipelines)
      else
        return status
      end
    end
  end
end end
