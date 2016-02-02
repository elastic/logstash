# encoding: utf-8
require "app"
require "app/system/basicinfo_command"

module LogStash::Api
  class Root < BaseApp

    get "/" do
      command = factory.build(:system_basic_info)
      respond_with command.run
    end

  end
end
