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
      pipelines.compute(pipeline_id) do |_,pipeline|
        pipeline.shutdown { LogStash::ShutdownWatcher.start(pipeline) }
        pipeline.thread.join
        nil # delete the pipeline
      end
      # If we reach this part of the code we have succeeded because
      # the shutdown call will block.
      return LogStash::ConvergeResult::SuccessfulAction.new
    end

    def to_s
      "PipelineAction::Stop<#{pipeline_id}>"
    end
  end
end end
