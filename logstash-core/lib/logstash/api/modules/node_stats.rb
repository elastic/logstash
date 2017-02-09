# encoding: utf-8
module LogStash
  module Api
    module Modules
      class NodeStats < ::LogStash::Api::Modules::Base

        before do
          @stats = factory.build(:stats)
        end

        get "/?:filter?" do
          payload = {
            :jvm => jvm_payload,
            :process => process_payload,
            :pipeline => pipeline_payload,
            :reloads => reloads,
            :os => os_payload
          }
          respond_with(payload, {:filter => params["filter"]})
        end

        private
        def os_payload
          @stats.os
        end

        def events_payload
          @stats.events
        end

        def jvm_payload
          @stats.jvm
        end

        def reloads
          @stats.reloads
        end

        def process_payload
          @stats.process
        end

        def mem_payload
          @stats.memory
        end

        def pipeline_payload
          @stats.pipeline
        end
      end
    end
  end
end
