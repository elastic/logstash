# encoding: utf-8
require "logstash/pipeline_action/base"
require "logstash/shutdown_watcher"
require "logstash/converge_result"

module LogStash module PipelineAction
  class Stop < Base
    attr_reader :pipeline_id

    def initialize(pipeline_id)
      @pipeline_id = pipeline_id
    end

    def execute(agent, pipelines)
      pipeline = pipelines[pipeline_id]
      pipeline.shutdown { LogStash::ShutdownWatcher.start(pipeline) }
      pipeline.thread.join
      pipelines.delete(pipeline_id)
      # If we reach this part of the code we have succeeded because
      # the shutdown call will block.
      return LogStash::ConvergeResult::SuccessfulAction.new
    end
  end
end end
