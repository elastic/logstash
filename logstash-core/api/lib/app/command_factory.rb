# encoding: utf-8
require "app/service"
require "app/system/info_command"
require "app/pipeline/stats_command"

module LogStash::Api
  class CommandFactory

    attr_reader :factory, :service

    def initialize(service)
      @service = service
      @factory = {}.merge(
        :system_info => SystemInfoCommand,
        :stats_command => PipelineStatsCommand
      )
    end

    def build(klass)
      factory[klass].new(service)
    end
  end
end
