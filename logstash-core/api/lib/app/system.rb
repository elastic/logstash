# encoding: utf-8
require "app"
require "app/system/info_command"

module LogStash::Api
  class System < BaseApp

    # Show general information about the system
    #  - Logstash version
    #  - host name
    #  - # of installed plugins
    #  - list of installed plugins (with versions)
    get "/" do
      command = factory.build(:system_info)
      respond_with command.run
    end

    # Show stats information
    # - CPU
    # - Memory
    # - # open file descriptors
    get "/stats" do
      respond_with({ "system" => { "stats" => true}})
    end

  end
end
