require "logstash/namespace"
require "logstash/errors"
require "logstash/pluginmanager/install"
require "logstash/pluginmanager/uninstall"
require "logstash/pluginmanager/list"
require "logstash/pluginmanager/update"
require "logstash/pluginmanager/util"
require "logstash/patches/maven_tools_patch"
require "clamp"

module LogStash
  module PluginManager
    class Error < StandardError; end

    class Main < Clamp::Command
      subcommand "install", "Install a plugin", LogStash::PluginManager::Install
      subcommand "uninstall", "Uninstall a plugin", LogStash::PluginManager::Uninstall
      subcommand "update", "Install a plugin", LogStash::PluginManager::Update
      subcommand "list", "List all installed plugins", LogStash::PluginManager::List
    end
  end
end
