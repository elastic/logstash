# encoding: utf-8
require "app"

module LogStash::Api
  class NodeStats < BaseApp

    helpers AppHelpers


    # Global _stats resource where all information is 
    # retrieved and show
    get "/" do
      events_command = factory.build(:events_command)
      payload = {
        :events => events_command.run,
        :jvm => jvm_payload
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
      respond_with jvm_payload
    end

    private

    def jvm_payload
      command = factory.build(:memory_command)
      {
        :timestamp => command.started_at,
        :uptime_in_millis => command.uptime,
        :mem => command.run
      }
    end
  end
end
