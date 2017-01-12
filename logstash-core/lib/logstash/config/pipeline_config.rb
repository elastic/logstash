# encoding: utf-8

module LogStash module Config
  class PipelineConfig
    attr_reader :pipeline_name, :config_parts

    def initialize(pipeline_name, config_parts)
      @pipeline_name = pipeline_name
      @config_parts = config_parts
      @settings = settings
      add_missing_parts!
    end

    # TODO,
    #  - we need to make sure the config can also have some reference to a settings
    #   - in the case of ES he can probably return the number of workers/batch/size
    #   - in the case of the file settings, it will come from eithet the default when using the -e or the -f
    #   - Or it could come when a user is preconfiguring a pipelines key in the logstash.yml file
    def add_missing_parts!
    end
  end
end end
