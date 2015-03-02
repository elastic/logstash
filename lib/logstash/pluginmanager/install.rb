require 'clamp'
require 'logstash/namespace'
require 'logstash/environment'
require 'logstash/pluginmanager/util'
require 'jar-dependencies'
require 'jar_install_post_install_hook'
require 'file-dependencies/gem'

require "logstash/gemfile"
require "logstash/bundler"

class LogStash::PluginManager::Install < Clamp::Command
  parameter "[PLUGIN] ...", "plugin name(s) or file"
  option "--version", "VERSION", "version of the plugin to install"
  option "--[no-]verify", :flag, "verify plugin validity before installation", :default => true
  option "--development", :flag, "install all development dependencies of currently installed plugins", :default => false

  # the install logic below support installing multiple plugins with each a version specification
  # but the argument parsing does not support it for now so currently if specifying --version only
  # one plugin name can be also specified.
  #
  # TODO: find right syntax to allow specifying list of plugins with optional version specification for each

  def execute
    if development?
      raise(LogStash::PluginManager::Error, "Cannot specify plugin(s) with --development, it will add the development dependencies of the currently installed plugins") unless plugin_list.empty?
    else
      raise(LogStash::PluginManager::Error, "No plugin specified") if plugin_list.empty? && verify?

      # temporary until we fullfil TODO ^^
      raise(LogStash::PluginManager::Error, "Only 1 plugin name can be specified with --version") if version && plugin_list.size > 1
    end
    raise(LogStash::PluginManager::Error, "File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting") unless File.writable?(LogStash::Environment::GEMFILE_PATH)

    gemfile = LogStash::Gemfile.open(LogStash::Environment::GEMFILE_PATH)
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    # force Rubygems sources to our Gemfile sources
    Gem.sources = gemfile.gemset.sources

    # install_list will be an array of [plugin name, version] tuples, version can be nil
    install_list = []

    if development?
      specs = LogStash::PluginManager.all_installed_plugins_gem_specs(gemfile)
      install_list = specs.inject([]) do |result, spec|
        result = result + spec.dependencies.select{|dep| dep.type == :development}.map{|dep| [dep.name] + dep.requirement.as_list + [{:group => :development}]}
      end
    else
      # at this point we know that plugin_list is not empty and if the --version is specified there is only one plugin in plugin_list

      install_list = version ? [plugin_list << version] : plugin_list.map{|plugin| [plugin, nil]}

      install_list.each do |plugin, version|
        puts("Validating #{[plugin, version].compact.join("-")}")
        raise(LogStash::PluginManager::Error, "Installation aborted") unless LogStash::PluginManager.logstash_plugin?(plugin, version)
      end if verify?

      # at this point we know that we either have a valid gem name & version or a valid .gem file path
    end

    install_list = LogStash::PluginManager.merge_duplicates(install_list)
    install_list.each{|plugin, version| gemfile.update(plugin, version)}
    gemfile.save

    puts("Installing" + (install_list.empty? ? "..." : " " + install_list.map{|plugin, version| plugin}.join(", ")))

    bundler_options = {:install => true}
    bundler_options[:without] = [] if development?

    # any errors will be logged to $stderr by invoke_bundler!
    output, exception = LogStash::Bundler.invoke_bundler!(bundler_options)

    if ENV["DEBUG"]
      $stderr.puts(output)
      $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
    end

    if exception
      # revert to original Gemfile content
      gemfile.gemset = original_gemset
      gemfile.save
      raise(LogStash::PluginManager::Error, "Installation aborted")
    end

    puts("Installation successful")

  ensure
    gemfile.close if gemfile
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
end # class Logstash::PluginManager
