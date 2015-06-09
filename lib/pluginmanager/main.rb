# encoding: utf-8
$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "..", "..")))

require "bootstrap/environment"

ENV["GEM_HOME"] = ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
Gem.use_paths(LogStash::Environment.logstash_gem_home)

module LogStash
  module PluginManager
  end
end

require "clamp"
require "pluginmanager/util"
require "pluginmanager/gemfile"
require "pluginmanager/install"
require "pluginmanager/uninstall"
require "pluginmanager/list"
require "pluginmanager/update"
require "pluginmanager/pack"
require "pluginmanager/unpack"

module LogStash
  module PluginManager
    class Error < StandardError; end

    class Main < Clamp::Command
      subcommand "install", "Install a plugin", LogStash::PluginManager::Install
      subcommand "uninstall", "Uninstall a plugin", LogStash::PluginManager::Uninstall
      subcommand "update", "Update a plugin", LogStash::PluginManager::Update
      subcommand "pack", "Package currently installed plugins", LogStash::PluginManager::Pack
      subcommand "unpack", "Unpack packaged plugins", LogStash::PluginManager::Unpack
      subcommand "list", "List all installed plugins", LogStash::PluginManager::List
    end
  end
end

if $0 == __FILE__
  begin
    LogStash::PluginManager::Main.run("bin/plugin", ARGV)
  rescue LogStash::PluginManager::Error => e
    $stderr.puts(e.message)
    exit(1)
  end
end
