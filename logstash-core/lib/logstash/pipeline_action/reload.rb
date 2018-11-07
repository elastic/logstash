# encoding: utf-8
require "logstash/pipeline_action/base"
require "logstash/pipeline_action/create"
require "logstash/pipeline_action/stop"

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

    def to_s
      "PipelineAction::Reload<#{pipeline_id}>"
    end

    def execute(agent, pipelines)
      old_pipeline = pipelines[pipeline_id]

      if !old_pipeline.reloadable?
        return LogStash::ConvergeResult::FailedAction.new("Cannot reload pipeline, because the existing pipeline is not reloadable")
      end

      begin
        pipeline_validator =
          if @pipeline_config.settings.get_value("pipeline.java_execution")
            LogStash::JavaBasePipeline.new(@pipeline_config, nil, logger, nil)
          else
            agent.exclusive do
              # The Ruby pipeline initialization is not thread safe because of the module level
              # shared state in LogsStash::Config::AST. When using multiple pipelines this can gets
              # executed simultaneously in different threads and we need to synchonize this initialization.
              LogStash::BasePipeline.new(@pipeline_config)
            end
          end
      rescue => e
        return LogStash::ConvergeResult::FailedAction.from_exception(e)
      end

      if !pipeline_validator.reloadable?
        return LogStash::ConvergeResult::FailedAction.new("Cannot reload pipeline, because the new pipeline is not reloadable")
      end

      logger.info("Reloading pipeline", "pipeline.id" => pipeline_id)

      pipelines.compute(pipeline_id) do |_,pipeline|
        status = Stop.new(pipeline_id).execute(agent, pipelines)

        if status
          return Create.new(@pipeline_config, @metric).execute(agent, pipelines)
        else
          return status
        end
        pipeline
      end
    end
  end
end end
