# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
require "pluginmanager/remove"
require "pluginmanager/list"
require "pluginmanager/update"
require "pluginmanager/pack"
require "pluginmanager/unpack"
require "pluginmanager/generate"
require "pluginmanager/prepare_offline_pack"
require "pluginmanager/proxy_support"
configure_proxy

module LogStash
  module PluginManager
    class Error < StandardError; end

    class Main < Clamp::Command
      subcommand "list", "List all installed Logstash plugins", LogStash::PluginManager::List
      subcommand "install", "Install a Logstash plugin", LogStash::PluginManager::Install
      subcommand "remove", "Remove a Logstash plugin", LogStash::PluginManager::Remove
      subcommand "update", "Update a plugin", LogStash::PluginManager::Update
      subcommand "pack", "Package currently installed plugins, Deprecated: Please use prepare-offline-pack instead", LogStash::PluginManager::Pack
      subcommand "unpack", "Unpack packaged plugins, Deprecated: Please use prepare-offline-pack instead", LogStash::PluginManager::Unpack
      subcommand "generate", "Create the foundation for a new plugin", LogStash::PluginManager::Generate
      subcommand "uninstall", "Uninstall a plugin. Deprecated: Please use remove instead", LogStash::PluginManager::Remove
      subcommand "prepare-offline-pack", "Create an archive of specified plugins to use for offline installation", LogStash::PluginManager::PrepareOfflinePack
    end
  end
end

if $0 == __FILE__
  begin
    LogStash::PluginManager::Main.run("bin/logstash-plugin", ARGV)
  rescue LogStash::PluginManager::Error => e
    $stderr.puts(e.message)
    exit(1)
  end
end
