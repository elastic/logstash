# encoding: utf-8
require "logstash/settings"

module LogStash
  class PipelineSettings < Settings

    # there are settings that the pipeline uses and can be changed per pipeline instance
    SETTINGS_WHITE_LIST = [
      "config.debug",
      "config.support_escapes",
      "config.reload.automatic",
      "config.reload.interval",
      "config.string",
      "dead_letter_queue.enable",
      "dead_letter_queue.max_bytes",
      "metric.collect",
      "pipeline.java_execution",
      "pipeline.plugin_classloaders",
      "path.config",
      "path.dead_letter_queue",
      "path.queue",
      "pipeline.batch.delay",
      "pipeline.batch.size",
      "pipeline.id",
      "pipeline.reloadable",
      "pipeline.system",
      "pipeline.workers",
      "queue.checkpoint.acks",
      "queue.checkpoint.interval",
      "queue.checkpoint.writes",
      "queue.checkpoint.retry",
      "queue.drain",
      "queue.max_bytes",
      "queue.max_events",
      "queue.page_capacity",
      "queue.type",
    ]

    # register a set of settings that is used as the default set of pipelines settings
    def self.from_settings(settings)
      pipeline_settings = self.new
      SETTINGS_WHITE_LIST.each do |setting|
        pipeline_settings.register(settings.get_setting(setting).clone)
      end
      pipeline_settings
    end

    def register(setting)
      unless SETTINGS_WHITE_LIST.include?(setting.name)
        raise ArgumentError.new("Only pipeline related settings can be registered in a PipelineSettings object. Received \"#{setting.name}\". Allowed settings: #{SETTINGS_WHITE_LIST}")
      end
      super(setting)
    end
  end
end
