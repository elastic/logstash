# encoding: utf-8
require "logstash/config/source_loader/config_string"
require "logstash/config/source_loader/local_file"
require "logstash/config/source_loader/remote_file"
require "thread"

module LogStash module Config
  class SourceLoader
    def initialize(source_loaders)
      @source_loaders = source_loaders
    end

    def pipeline_configs
      @sources_loaders.collect(&:pipeline_configs)
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

    def initialize
      @settings = settings
    end

    def create
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
