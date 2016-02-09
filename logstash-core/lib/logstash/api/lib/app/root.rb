# encoding: utf-8
require "app"

module LogStash::Api
  class Root < BaseApp

    get "/" do
      command = factory.build(:system_basic_info)
      respond_with command.run
    end

  end
end
