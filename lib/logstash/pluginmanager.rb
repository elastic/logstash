require "logstash/environment"

ENV["GEM_HOME"] = ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
Gem.use_paths(LogStash::Environment.logstash_gem_home)

require 'logstash/pluginmanager/main'

LogStash::PluginManager::Main.run("bin/plugin", ARGV) if __FILE__ == $0
