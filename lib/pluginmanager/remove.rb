# encoding: utf-8
require "pluginmanager/bundler/logstash_uninstall"
require "pluginmanager/command"

class LogStash::PluginManager::Remove < LogStash::PluginManager::Command
  parameter "PLUGIN", "plugin name"

  def execute
    signal_error("File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting") unless File.writable?(LogStash::Environment::GEMFILE_PATH)

    ##
    # Need to setup the bundler status to enable uninstall of plugins
    # installed as local_gems, otherwise gem:specification is not
    # finding the plugins
    ##
    LogStash::Bundler.setup!({:without => [:build, :development]})

    # make sure this is an installed plugin and present in Gemfile.
    # it is not possible to uninstall a dependency not listed in the Gemfile, for example a dependent codec
    signal_error("This plugin has not been previously installed") unless LogStash::PluginManager.installed_plugin?(plugin, gemfile)

    exit(1) unless ::Bundler::LogstashUninstall.uninstall!(plugin)

    remove_unused_locally_installed_gems!
  rescue => exception
    report_exception("Operation aborted, cannot remove plugin.", exception)
  end
end
