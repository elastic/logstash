# encoding: utf-8
require "app"

module LogStash::Api
  class Stats < BaseApp

    helpers AppHelpers

    # return hot threads information
    get "/jvm" do
      command = factory.build(:memory_command)
      jvm_payload = {
        :timestamp => command.started_at,
        :uptime_in_millis => command.uptime,
        :mem => command.run
      }
      respond_with({:jvm => jvm_payload})
    end

  end
end
