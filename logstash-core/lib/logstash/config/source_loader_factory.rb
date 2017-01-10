# encoding: utf-8
require "logstash/config/source_loader/config_string"
require "logstash/config/source_loader/local_file"
require "logstash/config/source_loader/remote_file"
require "thread"

module LogStash module Config
  class PipelineConfig
    attr_reader :pipeline_name

    def initialize(pipeline_name, config_parts)
      @pipeline_name = pipeline_name
      @config_parts = config_parts.sort # TODO make is invariant
    end

    def config_parts
      @config_parts
    end
  end

  class SourceLoader
    def initialize(sources)
      @sources = sources
    end

    def get_pipelines
      pipeline_configs = []

      @sources
        .collect(&:get)
        .flatten
        .group_by(&:pipeline_name).each do |pipeline_name, config_parts|
        pipeline_configs << PipelineConfig.new(pipeline_name, config_parts)
      end
    end
  end

  class SourceLoaderFactory
    include LogStash::Util::Loggable

    @@SOURCE_LOADERS_MUTEX = Mutex.new
    @@SOURCE_LOADERS = Set.new([
      LogStash::Config::SourceLoader::ConfigString,
      LogStash::Config::SourceLoader::RemoteFile,
      LogStash::Config::SourceLoader::LocalFile
    ])

    def create(settings)
      loaders = []

      source_loaders do |config_source|
        if config_source.match?(@settings)
          sources << config_source.new(@settings)
        end
      end

      if loaders.empty?
        raise "Can't find a appropriate config loader with current settings"
      else
        SourceLoader.new(loaders)
      end
    end

    def source_loaders
      @@SOURCE_LOADERS_MUTEX.synchronize do
        @@SOURCE_LOADERS.each do |config|
          yield config
        end
      end
    end

    def self.configure_sources(sources)
      logger.debug("Configure sources", sources)
      @@SOURCE_LOADERS_MUTEX.synchronize { @@SOURCE_LOADERS = sources }
    end
  end
end end
