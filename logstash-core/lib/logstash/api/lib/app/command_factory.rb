# encoding: utf-8
require "app/service"
require "app/commands/system/basicinfo_command"
require "app/commands/stats/events_command"
require "app/commands/stats/hotthreads_command"
require "app/commands/stats/memory_command"
require "app/commands/system/plugins_command"

module LogStash::Api
  class CommandFactory

    attr_reader :factory, :service

    def initialize(service)
      @service = service
      @factory = {}.merge(
        :system_basic_info => SystemBasicInfoCommand,
        :events_command => StatsEventsCommand,
        :hot_threads_command => HotThreadsCommand,
        :memory_command => JvmMemoryCommand,
        :plugins_command => PluginsCommand
      )
    end

    def build(klass)
      factory[klass].new(service)
    end
  end
end
