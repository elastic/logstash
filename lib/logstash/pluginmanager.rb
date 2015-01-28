require "logstash/environment"

ENV["GEM_HOME"] = ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
Gem.use_paths(LogStash::Environment.logstash_gem_home)

require 'logstash/pluginmanager/main'

if __FILE__ == $0
  begin
    LogStash::PluginManager::Main.run("bin/plugin", ARGV)
  rescue LogStash::PluginManager::Error => e
    $stderr.puts(e.message)
    exit(1)
  end
end
