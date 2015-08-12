# encoding: utf-8
require "pluginmanager/command"

class LogStash::PluginManager::Uninstall < LogStash::PluginManager::Command

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
    signal_error("This plugin has not been previously installed, aborting") unless LogStash::PluginManager.installed_plugin?(plugin, gemfile)

    # since we previously did a gemfile.find(plugin) there is no reason why
    # remove would not work (return nil) here
    if gemfile.remove(plugin)
      gemfile.save

      puts("Uninstalling #{plugin}")

      # any errors will be logged to $stderr by invoke!
      # output, exception = LogStash::Bundler.invoke!(:install => true, :clean => true)
      output = LogStash::Bundler.invoke!(:install => true, :clean => true)

      remove_unused_locally_installed_gems!
    end
  rescue => exception
    gemfile.restore!
    report_exception("Uninstall Aborted", exception)
  ensure
    display_bundler_output(output)
  end
end
