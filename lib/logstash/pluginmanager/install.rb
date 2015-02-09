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
  parameter "[PLUGIN] ...", "plugin name(s) or file"
  option "--version", "VERSION", "version of the plugin to install"
  option "--force", :flag, "force install without verifying plugin validity"

  # the install logic below support installing multiple plugins with each a version specification
  # but the argument parsing does not support it for now so currently if specifying --version only
  # one plugin name can be also specified.
  #
  # TODO: find right syntax to allow specifying list of plugins with optional version specification for each

  def execute
    return 99 if plugin_list.empty?

    if version && plugin_list.size > 1
      # temporary until we fullfil TODO ^^
      $stderr.puts("Only 1 plugin name can be specified with --version")
      return 99
    end

    unless File.writable?(LogStash::Environment::GEMFILE_PATH)
      $stderr.puts("File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting")
      return 99
    end

    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    # at this point we know that plugin_list is not empty and if the --version is specified there is only one plugin in plugin_list

    # plugins must be a list of [plugin name, version] tuples, version can be nil
    plugins = version ? [plugin_list << version] : plugin_list.map{|plugin| [plugin, nil]}

    # force Rubygems sources to our Gemfile sources
    Gem.sources = gemfile.gemset.sources

    plugins.each do |tuple|
      puts("Validating #{tuple.compact.join("-")}")
      return 99 unless LogStash::PluginManager.is_logstash_plugin?(*tuple)
    end unless force?

    # at this point we know that we either have a valid gem name & version or a valid .gem file path

    # if LogStash::PluginManager.is_plugin_file?(plugin)
    #   return 99 unless cache_gem_file(plugin)
    #   spec = LogStash::PluginManager.plugin_file_spec(plugin)
    #   gemfile.update(spec.name, spec.version.to_s)
    # else
    #   plugins.each{|tuple| gemfile.update(*tuple)}
    # end

    plugins.each{|tuple| gemfile.update(*tuple)}
    gemfile.save

    puts("Installing " + plugins.map{|tuple| tuple.compact.join("-")}.join(", "))

    # any errors will be logged to $stderr by invoke_bundler!
    output, exception = LogStash::PluginManager.invoke_bundler!(:install => true)

    if ENV["DEBUG"]
      $stderr.puts(output)
      $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
    end

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
end # class Logstash::PluginManager
