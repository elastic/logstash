# encoding: utf-8
require "app"
require "app/stats/events_command"

module LogStash::Api
  class Nodes < BaseApp

    helpers AppHelpers

    get '*/stats' do
      nodes = [] # all
      if params["captures"].count > 0
        nodes = params["captures"].first.gsub(/\//,"").split(",")
      end
     command = factory.build(:events_command)
     payload = {
       :nodes => [
        {
          :hostname   => "_local",
          :events => command.run
        }
       ]
     }
     respond_with payload
    end

  end
end
