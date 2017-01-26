# encoding: utf-8
require "logstash/api/commands/base"
require 'logstash/util/thread_dump'
require_relative "hot_threads_reporter"

module LogStash
  module Api
    module Commands
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

        def get_info(id)
          {:info => id}
        end

        def delete(id)
          begin
            @pipeline.dlq_manager.delete(id)
            {:deleted => true}
          rescue Error => e
            {:deleted => false, :reason => e.message}
          end
        end

        def rollover(new_id)
          begin
            @pipeline.dlq_manager.rollover(new_id)
            {:rollover => true}
          rescue Error => e
            {:rollover => false, :reason => e.message}
          end
        end
      end
    end
  end
end
