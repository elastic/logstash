# encoding: utf-8
require "app"

module LogStash::Api
  class NodeStats < BaseApp

    helpers AppHelpers


    # Global _stats resource where all information is 
    # retrieved and show
    get "/" do
      events_command = factory.build(:events_command)
      memory_command = factory.build(:memory_command)
      payload = {
        :events => events_command.run,
        :start_time_in_millis => events_command.started_at,
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
    get "/jvm" do
      command = factory.build(:memory_command)
      respond_with({ :memory => command.run })
    end

  end
end
