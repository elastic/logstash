require "logstash/environment"

ENV["GEM_HOME"] = ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
Gem.use_paths(LogStash::Environment.logstash_gem_home)

require 'logstash/pluginmanager/main'

plugin_manager = LogStash::PluginManager::Main.new($0)
begin
  plugin_manager.parse(ARGV)
  return plugin_manager.execute
rescue Clamp::HelpWanted => e
  show_help(e.command)
  return 0
end
