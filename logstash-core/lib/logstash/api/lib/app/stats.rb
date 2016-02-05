# encoding: utf-8
require "app"
require "app/stats/events_command"
require "app/stats/hotthreads_command"

module LogStash::Api
  class Stats < BaseApp

    helpers AppHelpers

    # return hot threads information
    get "/jvm" do
      command = factory.build(:memory_command)
      respond_with({ :memory => command.run })
    end

  end
end
