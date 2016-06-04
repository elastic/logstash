# encoding: utf-8
module LogStash
  module Api
    module Modules
      class NodeStats < ::LogStash::Api::Modules::Base
        #set :environment, :test
        #set :dump_errors, true
        #set :raise_errors, true
        #set :logging, Logger.new(STDERR)
        
        
        before do
          @stats = factory.build(:stats)
        end

        # Global _stats resource where all information is
        # retrieved and show
        get "/" do          
          payload = {
            :events => events_payload,
            :jvm => jvm_payload,
            :process => process_payload,
            :mem => mem_payload
          }

          respond_with payload
        end

        # Show all events stats information
        # (for ingested, emitted, dropped)
        # - #events since startup
        # - #data (bytes) since startup
        # - events/s
        # - bytes/s
        # - dropped events/s
        # - events in the pipeline
        get "/events" do
          respond_with({ :events => events_payload })
        end

        get "/jvm" do
          respond_with :jvm => jvm_payload
        end

        get "/process" do
          respond_with :process => process_payload
        end

        get "/mem" do
          respond_with :mem => mem_payload
        end

        get "/pipeline" do
          respond_with :pipeline => pipeline_payload
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
