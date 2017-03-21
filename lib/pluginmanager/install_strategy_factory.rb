# encoding: utf-8
require "pluginmanager/ui"
require "pluginmanager/pack_fetch_strategy/repository"
require "pluginmanager/pack_fetch_strategy/uri"

module LogStash module PluginManager
  class InstallStrategyFactory
    AVAILABLES_STRATEGIES = [
      LogStash::PluginManager::PackFetchStrategy::Uri,
      LogStash::PluginManager::PackFetchStrategy::Repository
    ]

    def self.create(plugins_args)
      plugin_name_or_uri = plugins_args.first
      return false if plugin_name_or_uri.nil? || plugin_name_or_uri.strip.empty?

      AVAILABLES_STRATEGIES.each do |strategy|
        if installer = strategy.get_installer_for(plugin_name_or_uri)
          return installer
        end
      end
      return false
    end
  end
end end
