# encoding: utf-8
require "logstash/config/source_loader/base"
require "logstash/config/config_part"

module LogStash module Config module SourceLoader
  class ConfigString < Base
    include LogStash::Util::Loggable

    class SourceMetadata
      def identifier
        :config_string
      end
    end

    def initialize(settings)
      super(settings)
    end

    def pipeline_configs
      [ConfigPart.new(self.class,
                       PIPELINE_NAME,
                       SourceMetadata.new,
                       settings.get("config.string"))]
    end

    def self.match?(settings)
      settings.get("config.string") && !settings.get("config.string").empty? ? true : false
    end
  end
end end end
