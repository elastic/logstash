require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager/util'
require 'jar-dependencies'
require 'jar_install_post_install_hook'
require 'file-dependencies/gem'

require "logstash/gemfile"
require "bundler/cli"
require "logstash/bundler_patch"

class LogStash::PluginManager::Update < Clamp::Command
  parameter "[PLUGIN]", "Plugin name to upgrade to latest version"

  def execute
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    # create list of plugins to update
    plugins = if plugin
      unless LogStash::PluginManager.is_installed_plugin?(plugin, gemfile)
        $stderr.puts("Plugin #{plugin} has not been previously installed, aborting")
        return 99
      end
      [plugin]
    else
      LogStash::PluginManager.all_installed_plugins(gemfile)
    end

    # remove any version constrain from the Gemfile so the plugin(s) can be updated to latest version
    # calling update without requiremend will remove any previous requirements
    plugins.each{|plugin| gemfile.update(plugin)}
    gemfile.save

    puts("Updating " + plugins.join(", "))

    # any errors will be logged to $stderr by invoke_bundler!
    output, exception = LogStash::PluginManager.invoke_bundler!(:update => (plugin || true))
    if exception
      # revert to original Gemfile content
      gemfile.gemset = original_gemset
      gemfile.save
      return 99
    end

    if ENV["DEBUG"]
      $stderr.puts(output)
      $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
    end
    return exception ? 99 : 0
  end
end
