# encoding: utf-8
module LogStash
  module Api
    module Modules
      class Stats < ::LogStash::Api::Modules::Base

        def stats_command
          factory.build(:stats)
        end

        # Global _stats resource where all information is 
        # retrieved and show
        get "/" do
          payload = {
            :events => stats_command.events,
            :jvm => { :memory => stats_command.memory }
          }
          respond_with payload
        end


        # return hot threads information
        get "/jvm" do
          jvm_payload = {
            :timestamp => stats_command.started_at,
            :uptime_in_millis => stats_command.uptime,
            :mem => stats_command.memory
          }
          respond_with({:jvm => jvm_payload})
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
          respond_with({ :events => stats_command.events })
        end

        # return hot threads information
        get "/jvm/hot_threads" do
          top_threads_count = params["threads"] || 3
          ignore_idle_threads = params["ignore_idle_threads"] || true
          options = {
            :threads => top_threads_count.to_i,
            :ignore_idle_threads => as_boolean(ignore_idle_threads)
          }

          respond_with(stats_command.hot_threads(options))
        end

        # return hot threads information
        get "/jvm/memory" do
          respond_with({ :memory => stats_command.memory })
        end
      end
    end
  end
end
