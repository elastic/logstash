# encoding: utf-8
require "app/service"
require "app/system/basicinfo_command"
require "app/stats/events_command"
require "app/stats/hotthreads_command"
require "app/stats/memory_command"

module LogStash::Api
  class CommandFactory

    attr_reader :factory, :service

    def initialize(service)
      @service = service
      @factory = {}.merge(
        :system_basic_info => SystemBasicInfoCommand,
        :events_command => StatsEventsCommand,
        :hot_threads_command => HotThreadsCommand,
        :memory_command => JvmMemoryCommand
      )
    end

    def build(klass)
      factory[klass].new(service)
    end
  end
end
