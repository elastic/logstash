# encoding: utf-8
require "pluginmanager/ui"
require "stud/temporary"

module LogStash module PluginManager
  class CustomGemIndexer
    GEMS_DIR = "gems"

    class << self
      # Copy the file to a specific format that `Gem::Indexer` can understand
      # See `#update_in_memory_index`
      def copy_to_local_source(temporary_directory)
        local_source = Stud::Temporary.pathname
        local_source_gems = ::File.join(local_source, GEMS_DIR)

        FileUtils.mkdir_p(local_source_gems)
        PluginManager.ui.debug("Creating the index structure format from #{temporary_directory} to #{local_source}")

        Dir.glob(::File.join(temporary_directory, "**", "*.gem")).each do |file|
          destination = ::File.join(local_source_gems, ::File.basename(file))
          FileUtils.cp(file, destination)
        end

        local_source
      end

      # *WARNING*: Bundler need to not be activated at this point because it won't find anything that
      # is not defined in the gemfile/lock combo
      #
      # This takes a folder with a special structure, will generate an index
      # similar to what rubygems do and make them available in the local program,
      # we use this **side effect** to validate theses gems with the current gemfile/lock.
      # Bundler will assume they are system gems and will use them when doing resolution checks.
      #
      #.
      # ├── gems
      # │   ├── addressable-2.4.0.gem
      # │   ├── cabin-0.9.0.gem
      # │   ├── ffi-1.9.14-java.gem
      # │   ├── gemoji-1.5.0.gem
      # │   ├── launchy-2.4.3-java.gem
      # │   ├── logstash-output-elasticsearch-5.2.0-java.gem
      # │   ├── logstash-output-secret-0.1.0.gem
      # │   ├── manticore-0.6.0-java.gem
      # │   ├── spoon-0.0.6.gem
      # │   └── stud-0.0.22.gem
      #
      # Right now this work fine, but I think we could also use Bundler's SourceList classes to handle the same thing
      def update_in_memory_index!(local_source)
        PluginManager.ui.debug("Generating indexes in #{local_source}")
        indexer = ::Gem::Indexer.new(local_source, { :build_modern => true})
        indexer.ui = ::Gem::SilentUI.new unless ENV["DEBUG"]
        indexer.generate_index
      end

      def index(path)
        local_source = copy_to_local_source(path)
        update_in_memory_index!(local_source)
        local_source
      end
    end
  end
end end
