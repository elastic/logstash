# encoding: utf-8
require "app"
require "app/stats/events_command"
require "app/stats/hotthreads_command"

module LogStash::Api
  class Stats < BaseApp

    helpers AppHelpers


    # Global _stats resource where all information is 
    # retrieved and show
    get "/" do
      events_command = factory.build(:events_command)
      memory_command = factory.build(:memory_command)
      payload = {
        :events => events_command.run,
        :jvm => { :memory => memory_command.run }
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
      command = factory.build(:events_command)
      respond_with({ :events => command.run })
    end

    # return hot threads information
    get "/jvm/hot_threads" do
      top_threads_count = params["threads"] || 3
      ignore_idle_threads = params["ignore_idle_threads"] || true
      options = {
        :threads => top_threads_count.to_i,
        :ignore_idle_threads => as_boolean(ignore_idle_threads)
      }
      command = factory.build(:hot_threads_command)
      respond_with(command.run(options), :string)
    end

    # return hot threads information
    get "/jvm/memory" do
      command = factory.build(:memory_command)
      respond_with({ :memory => command.run })
    end

  end
end
