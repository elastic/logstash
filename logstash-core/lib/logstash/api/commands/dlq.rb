# encoding: utf-8
require "logstash/api/commands/base"
require 'logstash/util/thread_dump'
require_relative "hot_threads_reporter"

module LogStash module Api module Commands
  class Dlq < Commands::Base
    def initialize(service = LogStash::Api::Service.instance)
      super(service)
      @pipeline_id, @pipeline = @service.agent.pipelines.first
    end

    def list
      {
        :pipeline => {
          @pipeline_id => @pipeline.dlq_manager.queues
        }
      }
    end
  end
end end end
