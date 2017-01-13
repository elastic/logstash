# encoding: utf-8

module LogStash module Config
  class PipelineConfig
    attr_reader :pipeline_name, :config_parts, :read_at

    def initialize(pipeline_name, config_parts)
      @pipeline_name = pipeline_name
      @config_parts = config_parts
      @settings = settings
      @read_at = Time.now
      add_missing_parts!
    end

    def inspect
      "PipelineConfig, pipeline_name: #{pipeline_name}, configs_parts#size: #{config_parts.size}, read_at: #{read_at}"
    end
  end
end end
