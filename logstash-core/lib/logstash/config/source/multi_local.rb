# encoding: utf-8
require "logstash/config/source/local"
require "logstash/util/loggable"
require "logstash/pipeline_settings"

module LogStash module Config module Source
  class MultiLocal < Local
    include LogStash::Util::Loggable

    def initialize(settings)
      @original_settings = settings
      super(settings)
    end

    def pipeline_configs
      pipelines = retrieve_yaml_pipelines()
      pipelines_settings = pipelines.map do |pipeline_settings|
        ::LogStash::PipelineSettings.from_settings(@original_settings.clone).merge(pipeline_settings)
      end
      detect_duplicate_pipelines(pipelines_settings)
      pipelines_settings.map do |pipeline_settings|
        @settings = pipeline_settings
        # this relies on instance variable @settings and the parent class' pipeline_configs
        # method. The alternative is to refactor most of the Local source methods to accept
        # a settings object instead of relying on @settings.
        super # create a PipelineConfig object based on @settings
      end.flatten
    end

    def match?
      uses_config_string = @original_settings.get_setting("config.string").set?
      uses_path_config = @original_settings.get_setting("path.config").set?
      return true if !uses_config_string && !uses_path_config
      if uses_path_config
        logger.warn("Ignoring the 'pipelines.yml' file because 'path.config' (-f) is being used.")
      elsif uses_config_string
        logger.warn("Ignoring the 'pipelines.yml' file because 'config.string' (-e) is being used.")
      end
      false
    end

    def retrieve_yaml_pipelines
      result = read_pipelines_from_yaml(pipelines_yaml_location)
      case result
      when Array
        result
      when false
        raise ConfigurationError.new("Pipelines YAML file is empty. Path: #{pipelines_yaml_location}")
      else
        raise ConfigurationError.new("Pipelines YAML file must contain an array of pipeline configs. Found \"#{result.class}\" in #{pipelines_yaml_location}")
      end
    end

    def read_pipelines_from_yaml(yaml_location)
      logger.debug("Reading pipeline configurations from YAML", :location => pipelines_yaml_location)
      ::YAML.load(IO.read(yaml_location))
    rescue => e
      raise ConfigurationError.new("Failed to read pipelines yaml file. Location: #{yaml_location}, Exception: #{e.inspect}")
    end

    def pipelines_yaml_location
      ::File.join(@original_settings.get("path.settings"), "pipelines.yml")
    end

    def detect_duplicate_pipelines(pipelines)
      duplicate_ids = pipelines.group_by {|pipeline| pipeline.get("pipeline.id") }.select {|k, v| v.size > 1 }.map {|k, v| k}
      if duplicate_ids.any?
        raise ConfigurationError.new("Pipelines YAML file contains duplicate pipeline ids: #{duplicate_ids.inspect}. Location: #{pipelines_yaml_location}")
      end
    end
  end
end end end
