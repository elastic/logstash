# encoding: utf-8
require "app/service"
require "app/system/info_command"
require "app/system/basicinfo_command"
require "app/stats/events_command"

module LogStash::Api
  class CommandFactory

    attr_reader :factory, :service

    def initialize(service)
      @service = service
      @factory = {}.merge(
        :system_basic_info => SystemBasicInfoCommand,
        :system_info => SystemInfoCommand,
        :events_command => StatsEventsCommand
      )
    end

    def build(klass)
      factory[klass].new(service)
    end
  end
end
