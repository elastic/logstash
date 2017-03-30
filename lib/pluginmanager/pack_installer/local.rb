# encoding: utf-8
require "pluginmanager/ui"
require "pluginmanager/bundler/logstash_injector"
require "pluginmanager/gem_installer"
require "pluginmanager/custom_gem_indexer"
require "pluginmanager/errors"
require "pluginmanager/pack_installer/pack"
require "bootstrap/util/compress"
require "rubygems/indexer"

module LogStash module PluginManager module PackInstaller
  class Local
    PACK_EXTENSION = ".zip"
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

      local_source = LogStash::PluginManager::CustomGemIndexer.index(uncompressed_path)

      # Try to add the gems to the current gemfile and lock file, if successful
      # both of them will be updated. This injector is similar to Bundler's own injector class
      # minus the support for additionals source and doing local resolution only.
      ::Bundler::LogstashInjector.inject!(pack)

      # When successful its safe to install the gem and their specifications in the bundle directory
      pack.gems.each do |packed_gem|
        PluginManager.ui.debug("Installing, #{packed_gem.name}, version: #{packed_gem.version} file: #{packed_gem.file}")
        LogStash::PluginManager::GemInstaller::install(packed_gem.file, packed_gem.plugin?)
      end
      PluginManager.ui.info("Install successful")
    rescue ::Bundler::BundlerError => e
      raise PluginManager::InstallError.new(e), "An error occurred went installing plugins"
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
  end
end end end
