# encoding: utf-8
require "app"
require "app/pipeline/stats_command"

module LogStash::Api
  class Pipeline < BaseApp

    helpers AppHelpers

    # Show general information about the pipeline
    #  - pipeline status
    #  - pipeline uptime
    get "/info" do
      respond_with({ "pipeline" => { "info" => true}})
    end


    # Show stats information
    # (for ingested, emitted, dropped)
    # - #events since startup
    # - #data (bytes) since startup
    # - events/s
    # - bytes/s
    # - dropped events/s
    # - events in the pipeline
    get "/stats" do
      command = factory.build(:stats_command)
      respond_with command.run
    end

    # Show information of
    # - list of active pipeline plugins (with versions)
    # - # of active input plugins
    # - # of active fitler plugins
    # - # of active codec plugins
    # - # of active output plugins
    get "/plugins" do
      respond_with({ "pipeline" => { "plugins" => true}})
    end

  end
end
