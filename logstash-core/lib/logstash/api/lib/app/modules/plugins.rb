# encoding: utf-8
require "app"

module LogStash::Api
  class Plugins < BaseApp

    helpers AppHelpers

    get "/" do
      command = factory.build(:plugins_command)
      respond_with(command.run())
    end

  end
end
