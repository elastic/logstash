# encoding: utf-8
require "app"
require "app/stats/events_command"
require "app/stats/hotthreads_command"

module LogStash::Api
  class Stats < BaseApp

    helpers AppHelpers

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
      respond_with command.run
    end

    # return hot threads information
    get "/jvm/hot_threads" do
      command = factory.build(:hot_threads_command)
      respond_with command.run
    end

    # return hot threads information
    get "/jvm/memory" do
      command = factory.build(:memory_command)
      respond_with command.run
    end

  end
end
