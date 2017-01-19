# encoding: utf-8
require "digest"

module LogStash module Config
  class PipelineConfig
    attr_reader :source, :pipeline_id, :config_parts, :settings, :read_at

    def initialize(source, pipeline_id, config_parts, settings)
      @source = source
      @pipeline_id = pipeline_id
      @config_parts = config_parts.sort_by { |config_part| [config_part.reader, config_part.source_id] }
      @settings = settings
      @read_at = Time.now
    end

    def config_hash
      @config_hash ||= Digest::SHA1.hexdigest(config_string)
    end

    def config_string
      @config_string = config_parts.collect(&:config_string).join("\n")
    end

    def ==(other)
      config_hash == other.config_hash && pipeline_id == other.pipeline_id
    end
  end
end end
