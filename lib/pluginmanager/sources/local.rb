# encoding: utf-8
require "rubygems/package"
require "pluginmanager/sources/base"
require "fileutils"

module LogStash::PluginManager::Sources

  class Local < Base

    def exist?
      ::File.exist?(uri.to_s)
    end

    def fetch(dest="")
      base_dir = (dest.empty? ? LogStash::Environment::LOGSTASH_HOME : dest )
      current_path = ::File.join(base_dir, ::File.basename(uri.to_s))
      ::FileUtils.cp(uri.to_s, current_path)
      [ current_path, "200" ]
    end

    def valid?
      super && exist?
    end
  end

end
