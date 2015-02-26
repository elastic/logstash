require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager/util'
require 'jar-dependencies'
require 'jar_install_post_install_hook'
require 'file-dependencies/gem'

require "logstash/gemfile"
require "logstash/bundler"

class LogStash::PluginManager::Update < Clamp::Command
  parameter "[PLUGIN] ...", "Plugin name(s) to upgrade to latest version"

  def execute
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    # create list of plugins to update
    plugins = unless plugin_list.empty?
      not_installed = plugin_list.find{|plugin| !LogStash::PluginManager.installed_plugin?(plugin, gemfile)}
      raise(LogStash::PluginManager::Error, "Plugin #{not_installed} has not been previously installed, aborting") if not_installed
      plugin_list
    else
      LogStash::PluginManager.all_installed_plugins_gem_specs(gemfile).map{|spec| spec.name}
    end

    # remove any version constrain from the Gemfile so the plugin(s) can be updated to latest version
    # calling update without requiremend will remove any previous requirements
    plugins.each{|plugin| gemfile.update(plugin)}
    gemfile.save

    puts("Updating " + plugins.join(", "))

    # any errors will be logged to $stderr by invoke_bundler!
    output, exception = LogStash::Bundler.invoke_bundler!(:update => plugins)
    output, exception = LogStash::Bundler.invoke_bundler!(:clean => true) unless exception

    if exception
      # revert to original Gemfile content
      gemfile.gemset = original_gemset
      gemfile.save

      report_exception(output, exception)
    end
  end

  def report_exception(output, exception)
    if ENV["DEBUG"]
      $stderr.puts(output)
      $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
    end

    raise(LogStash::PluginManager::Error, "Update aborted")
  end
end
