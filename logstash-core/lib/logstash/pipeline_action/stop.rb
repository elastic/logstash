# encoding: utf-8
require "logstash/pipeline_action/base"
require "logstash/shutdown_watcher"
require "logstash/converge_result"

module LogStash module PipelineAction
  class Stop < Base
    attr_reader :pipeline_id

    def initialize(pipeline_id, opts = {})
      @pipeline_id = pipeline_id
      @is_reload = opts.fetch(:reload, false)
    end

    def execute(agent, pipelines)
      pipeline = pipelines[pipeline_id]
      pipeline.shutdown { LogStash::ShutdownWatcher.start(pipeline) }
      pipelines.delete(pipeline_id)
        
      if collector = agent.metric.collector
        if @is_reload
          collector.clear("stats/pipelines/#{pipeline_id}/plugins")
          collector.clear("stats/pipelines/#{pipeline_id}/events")
        else
          collector.clear("stats/pipelines/#{pipeline_id}")
        end
      end
      # If we reach this part of the code we have succeeded because
      # the shutdown call will block.
      return LogStash::ConvergeResult::SuccessfulAction.new
    end
  end
end end
