require "logstash/namespace"
require "logstash/logging"
require "logstash/errors"
require "logstash/environment"
require "logstash/pluginmanager"
require "logstash/pluginmanager/util"
require "rubygems/uninstaller"
require "clamp"

class LogStash::PluginManager::Uninstall < Clamp::Command

  parameter "PLUGIN", "plugin name"

  public
  def execute
    ::Gem.configuration.verbose = false

    puts ("Validating removal of #{plugin}.")
    
    #
    # TODO: This is a special case, Bundler doesnt allow you to uninstall 1 gem.
    # Bundler will only uninstall the gems if they dont exist in his Gemfile.lock
    # (source of truth)
    #
    unless gem_data = LogStash::PluginManager::Util.logstash_plugin?(plugin)
      $stderr.puts ("Trying to remove a non logstash plugin. Aborting")
      return 99
    end

    puts ("Uninstalling plugin '#{plugin}' with version '#{gem_data.version}'.")
    ::Gem::Uninstaller.new(plugin, {}).uninstall
    return 
  end

end # class Logstash::PluginManager
