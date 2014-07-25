require "logstash/namespace"
require "logstash/errors"
require 'clamp'
require 'logstash/pluginmanager/install'
require 'logstash/pluginmanager/uninstall'
require 'logstash/pluginmanager/list'
require 'logstash/pluginmanager/update'
require 'logstash/pluginmanager/util'

class LogStash::PluginManager::Main < Clamp::Command

  subcommand "install", "Install a plugin", LogStash::PluginManager::Install
  subcommand "uninstall", "Uninstall a plugin", LogStash::PluginManager::Uninstall
  subcommand "update", "Install a plugin", LogStash::PluginManager::Update
  subcommand "list", "List all installed plugins", LogStash::PluginManager::List

end # class Logstash::PluginManager::Main
