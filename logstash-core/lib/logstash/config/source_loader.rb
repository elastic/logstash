# encoding: utf-8
require "logstash/config/source/local"
require "logstash/errors"
require "thread"
require "set"

module LogStash module Config
  class SourceLoader
    class Loader
      def initialize(loaders)
        @loaders = loaders
      end

      def fetch
        @loaders.collect(&:pipeline_configs).flatten
      end
    end

    include LogStash::Util::Loggable

    def initialize
      @source_loaders_mutex = Mutex.new
      @source_loaders = Set.new([LogStash::Config::Source::Local])
    end

    # This return a ConfigLoader object that will
    # abstract the call to the different sources and will return multiples pipeline
    def create(settings)
      loaders = []

      source_loaders do |config_source|
        if config_source.match?(settings)
          loaders << config_source.new(settings)
        end
      end

      if loaders.empty?

        # This shouldn't happen with the settings object or with any external plugins.
        # but lets add a guard so we fail fast.
        raise LogStash::InvalidSourceLoaderSettingError, "Can't find an appropriate config loader with current settings"
      else
        Loader.new(loaders)
      end
    end

    def source_loaders
      @source_loaders_mutex.synchronize do
        @source_loaders.each do |config|
          yield config
        end
      end
    end

    def configure_sources(sources)
      sources = Array(sources).to_set
      logger.debug("Configure sources", :sources => sources.collect(&:to_s))
      @source_loaders_mutex.synchronize { @source_loaders = sources }
    end

    def add_source(source)
      logger.debug("Adding source", :source => source.to_s)
      @source_loaders_mutex.synchronize { @source_loaders << source}
    end
  end

  SOURCE_LOADER = SourceLoader.new
end end
