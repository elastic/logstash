# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/errors"
require 'clamp'
require 'logstash/pluginmanager'
require 'logstash/pluginmanager/util'
require 'rubygems/uninstaller'

class LogStash::PluginManager::Uninstall < Clamp::Command

  parameter "PLUGIN", "plugin name"

  public
  def execute

    ::Gem.configuration.verbose = false

    puts ("Validating removal of #{plugin}.")
    
    unless gem_data = LogStash::PluginManager::Util.logstash_plugin?(plugin)
      $stderr.puts ("Trying to remove a non logstash plugin. Aborting")
      return 99
    end

    puts ("Uninstalling plugin '#{plugin}' with version '#{gem_data.version}'.")
    ::Gem::Uninstaller.new(plugin, {}).uninstall
    return 
  end

end # class Logstash::PluginManager
