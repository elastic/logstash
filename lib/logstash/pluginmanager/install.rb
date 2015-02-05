require 'clamp'
require 'logstash/namespace'
require 'logstash/environment'
require 'logstash/pluginmanager/util'
require 'jar-dependencies'
require 'jar_install_post_install_hook'
require 'file-dependencies/gem'

require "logstash/gemfile"
require "bundler/cli"
require "logstash/bundler_patch"


class LogStash::PluginManager::Install < Clamp::Command
  parameter "PLUGIN", "plugin name or file"
  option "--version", "VERSION", "version of the plugin to install"
  option "--proxy", "PROXY", "Use HTTP proxy for remote operations"

  def execute
    unless File.writable?(LogStash::Environment::GEMFILE_PATH)
      $stderr.puts("File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting")
      return 99
    end

    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    # force Rubygems sources to our Gemfile sources
    Gem.sources = gemfile.gemset.sources

    puts("Validating #{plugin} #{version}")
    return 99 unless LogStash::PluginManager.is_logstash_plugin?(plugin, version)

    # at this point we know that we either have a valid gem name & version or a valid .gem file path

    if LogStash::PluginManager.is_plugin_file?(plugin)
      return 99 unless cache_gem_file(plugin)
      spec = LogStash::PluginManager.plugin_file_spec(plugin)
      gemfile.update(spec.name, spec.version.to_s)
    else
      gemfile.update(plugin, version)
    end
    gemfile.save

    puts("Installing #{plugin} #{version}")

    # any errors will be logged to $stderr by bundle_install!
    output, exception = LogStash::PluginManager.bundle_install!
    if exception
      # revert to original Gemfile content
      gemfile.gemset = original_gemset
      gemfile.save
      return 99
    end

    return 0
  end

  # copy .gem file into bundler cache directory, log any error to $stderr
  # @param path [String] the source .gem file to copy
  # @return [Boolean] true if successful
  def cache_gem_file(path)
    dest = ::File.join(LogStash::Environment.logstash_gem_home, "cache")
    begin
      FileUtils.cp(path, dest)
    rescue => e
      $stderr.puts("Error copying #{plugin} to #{dest}, caused by #{e.class}")
      return false
    end
    true
  end

  # def execute
  #   LogStash::Environment.load_logstash_gemspec!

  #   ::Gem.configuration.verbose = false
  #   ::Gem.configuration[:http_proxy] = proxy

  #   puts ("validating #{plugin} #{version}")

  #   unless gem_path = (plugin =~ /\.gem$/ && File.file?(plugin)) ? plugin : LogStash::PluginManager::Util.download_gem(plugin, version)
  #     $stderr.puts ("Plugin does not exist '#{plugin}'. Aborting")
  #     return 99
  #   end

  #   unless gem_meta = LogStash::PluginManager::Util.logstash_plugin?(gem_path)
  #     $stderr.puts ("Invalid logstash plugin gem '#{plugin}'. Aborting...")
  #     return 99
  #   end

  #   puts ("Valid logstash plugin. Continuing...")

  #   if LogStash::PluginManager::Util.installed?(gem_meta.name)

  #     current = Gem::Specification.find_by_name(gem_meta.name)
  #     if Gem::Version.new(current.version) > Gem::Version.new(gem_meta.version)
  #       unless LogStash::PluginManager::Util.ask_yesno("Do you wish to downgrade this plugin?")
  #         $stderr.puts("Aborting installation")
  #         return 99
  #       end
  #     end

  #     puts ("removing existing plugin before installation")
  #     ::Gem.done_installing_hooks.clear
  #     ::Gem::Uninstaller.new(gem_meta.name, {:force => true}).uninstall
  #   end

  #   ::Gem.configuration.verbose = false
  #   FileDependencies::Gem.hook
  #   options = {}
  #   options[:document] = []
  #   if LogStash::Environment.test?
  #     # This two options are the ones used to ask the rubygems to install
  #     # all development dependencies as you can do from the command line
  #     # tool.
  #     #
  #     # :development option for installing development dependencies.
  #     # :dev_shallow option for checking on the top level gems if there.
  #     #
  #     # Comments from the command line tool.
  #     # --development     - Install additional development dependencies
  #     #
  #     # Links: https://github.com/rubygems/rubygems/blob/master/lib/rubygems/install_update_options.rb#L150
  #     #        http://guides.rubygems.org/command-reference/#gem-install
  #     options[:dev_shallow] = true
  #     options[:development] = true
  #   end
  #   inst = Gem::DependencyInstaller.new(options)
  #   inst.install plugin, version
  #   specs = inst.installed_gems.detect { |gemspec| gemspec.name == gem_meta.name }
  #   puts ("Successfully installed '#{specs.name}' with version '#{specs.version}'")
  #   return 0
  # end

end # class Logstash::PluginManager
