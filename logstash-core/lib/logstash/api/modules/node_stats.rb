# encoding: utf-8
module LogStash
  module Api
    module Modules
      class NodeStats < ::LogStash::Api::Modules::Base

        before do
          @stats = factory.build(:stats)
        end

        get "/?:filter?" do
          selected_fields = extract_fields(params["filter"].to_s.strip)
          payload = {
            :jvm => jvm_payload,
            :process => process_payload,
            :mem => mem_payload,
            :pipeline => pipeline_payload
          }
          payload.select! { |k,v| selected_fields.include?(k) } unless selected_fields.empty?
          respond_with payload
        end

        private

        def events_payload
          @stats.events
        end

        def jvm_payload
          @stats.jvm
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
