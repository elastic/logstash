require "logstash/namespace"
require "logstash/logging"
require "logstash/errors"
require "logstash/environment"
require "logstash/pluginmanager/util"
require "clamp"

require "logstash/gemfile"
require "logstash/bundler"

class LogStash::PluginManager::Uninstall < Clamp::Command
  parameter "PLUGIN", "plugin name"


  def execute
    raise(LogStash::PluginManager::Error, "File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting") unless File.writable?(LogStash::Environment::GEMFILE_PATH)

    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    # make sure this is an installed plugin and present in Gemfile.
    # it is not possible to uninstall a dependency not listed in the Gemfile, for example a dependent codec
    raise(LogStash::PluginManager::Error, "This plugin has not been previously installed, aborting") unless LogStash::PluginManager.installed_plugin?(plugin, gemfile)

    # since we previously did a gemfile.find(plugin) there is no reason why
    # remove would not work (return nil) here
    if gemfile.remove(plugin)
      gemfile.save

      puts("Uninstalling #{plugin}")

      # any errors will be logged to $stderr by invoke_bundler!
      output, exception = LogStash::Bundler.invoke_bundler!(:install => true, :clean => true)

      if ENV["DEBUG"]
        $stderr.puts(output)
        $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
      end

      if exception
        # revert to original Gemfile content
        gemfile.gemset = original_gemset
        gemfile.save
        raise(LogStash::PluginManager::Error, "Uninstall aborted")
      end
    end
  end
end
