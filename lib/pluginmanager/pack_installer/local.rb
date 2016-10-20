# encoding: utf-8
require "pluginmanager/ui"
require "pluginmanager/bundler/logstash_injector"
require "pluginmanager/gem_installer"
require "pluginmanager/errors"
require "pluginmanager/pack_installer/pack"
require "bootstrap/util/compress"
require "rubygems/indexer"

module LogStash module PluginManager module PackInstaller
  class Local
    PACK_EXTENSION = ".zip"
    GEMS_DIR = "gems"
    LOGSTASH_PATTERN_RE = /logstash\/?/

    attr_reader :local_file

    def initialize(local_file)
      @local_file = local_file
    end

    def execute
      raise PluginManager::FileNotFoundError, "Can't file local file #{local_file}" unless ::File.exist?(local_file)
      raise PluginManager::InvalidPackError, "Invalid format, the pack must be in zip format" unless valid_format?(local_file)

      PluginManager.ui.info("Installing file: #{local_file}")
      uncompressed_path = uncompress(local_file)
      PluginManager.ui.debug("Pack uncompressed to #{uncompressed_path}")
      pack = LogStash::PluginManager::PackInstaller::Pack.new(uncompressed_path)
      raise PluginManager::InvalidPackError, "The pack must contains at least one plugin" unless pack.valid?

      local_source = move_to_local_source(uncompressed_path)
      update_in_memory_index(local_source)

      # Try to add the gems to the current gemfile and lock file, if successful
      # both of them will be updated. This injector is similar to Bundler's own injector class
      # minus the support for additionals source and doing local resolution only.
      added = ::Bundler::LogstashInjector.inject!(pack.plugins)

      # When successfull its safe to install the gem and their specifications in the bundle directory
      pack.gems.each do |packed_gem|
        PluginManager.ui.debug("Installing, #{packed_gem.name}, version: #{packed_gem.version} file: #{packed_gem.file}")
        LogStash::PluginManager::GemInstaller::install(packed_gem.file, packed_gem.plugin?)
      end
      PluginManager.ui.info("Install successful")
    rescue ::Bundler::BundlerError => e
      raise PluginManager::InstallError.new(e), "An error occurent went installing plugins"
    ensure
      FileUtils.rm_rf(uncompressed_path) if uncompressed_path && Dir.exist?(uncompressed_path)
      FileUtils.rm_rf(local_source) if local_source && Dir.exist?(local_source)
    end

    private
    def uncompress(source)
      temporary_directory = Stud::Temporary.pathname
      LogStash::Util::Zip.extract(source, temporary_directory, LOGSTASH_PATTERN_RE)
      temporary_directory
    rescue Zip::Error => e
      # OK Zip's handling of file is bit weird, if the file exist but is not a valid zip, it will raise
      # a `Zip::Error` exception with a file not found message...
      raise InvalidPackError, "Cannot uncompress the zip: #{source}"
    end

    def valid_format?(local_file)
      ::File.extname(local_file).downcase == PACK_EXTENSION
    end

    # Copy the file to a specific format that `Gem::Indexer` can understand
    # See `#update_in_memory_index`
    def move_to_local_source(temporary_directory)
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
    def update_in_memory_index(local_source)
      PluginManager.ui.debug("Generating indexes in #{local_source}")
      indexer = ::Gem::Indexer.new(local_source, { :build_modern => true})
      indexer.ui = ::Gem::SilentUI.new unless ENV["DEBUG"]
      indexer.generate_index
    end
  end
end end end
