require "logstash/namespace"
require "logstash/logging"
require "logstash/errors"
require "logstash/environment"
require "logstash/pluginmanager/util"
require "logstash/pluginmanager/command"
require "clamp"

require "logstash/gemfile"
require "logstash/bundler"

class LogStash::PluginManager::Uninstall < LogStash::PluginManager::Command
  parameter "PLUGIN", "plugin name"

  def execute
    LogStash::Environment.bundler_setup!

    signal_error("File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting") unless File.writable?(LogStash::Environment::GEMFILE_PATH)

    # make sure this is an installed plugin and present in Gemfile.
    # it is not possible to uninstall a dependency not listed in the Gemfile, for example a dependent codec
    signal_error("This plugin has not been previously installed, aborting") unless LogStash::PluginManager.installed_plugin?(plugin, gemfile)

    # since we previously did a gemfile.find(plugin) there is no reason why
    # remove would not work (return nil) here
    if gemfile.remove(plugin)
      gemfile.save

      puts("Uninstalling #{plugin}")

      # any errors will be logged to $stderr by invoke_bundler!
      # output, exception = LogStash::Bundler.invoke_bundler!(:install => true, :clean => true)
      output = LogStash::Bundler.invoke_bundler!(:install => true)
      
      remove_unused_locally_installed_gems!
    end
  rescue => exception
    gemfile.restore!
    report_exception("Uninstall Aborted", exception)
  ensure
    display_bundler_output(output)
  end
end
