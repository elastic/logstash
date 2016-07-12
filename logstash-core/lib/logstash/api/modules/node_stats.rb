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
            :jvm => jvm_payload,
            :process => process_payload,
            :pipeline => pipeline_payload
          }

          respond_with payload
        end

        get "/jvm" do
          respond_with :jvm => jvm_payload
        end

        get "/process" do
          respond_with :process => process_payload
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
