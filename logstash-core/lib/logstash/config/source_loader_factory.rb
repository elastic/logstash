# encoding: utf-8
require "logstash/config/source/local"
require "thread"

module LogStash module Config
  class SourceLoaderFactory
    class ConfigLoader
      def initialize(source_loaders)
        @source_loaders = source_loaders
      end

      def pipeline_configs
        @source_loaders.collect(&:pipeline_configs).flatten
      end
    end

    include LogStash::Util::Loggable

    @@SOURCE_LOADERS_MUTEX = Mutex.new
    @@SOURCE_LOADERS = Set.new([
      LogStash::Config::Source::Local
    ])

    def initialize(settings)
      @settings = settings
    end

    # This return a ConfigLoader object that will
    # abstract the call to the different sources, or the different configured pipeline
    def create
      loaders = []

      source_loaders do |config_source|
        if config_source.match?(@settings)
          loaders << config_source.new(@settings)
        end
      end

      if loaders.empty?
        raise "Can't find an appropriate config loader with current settings"
      else
        ConfigLoader.new(loaders)
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
