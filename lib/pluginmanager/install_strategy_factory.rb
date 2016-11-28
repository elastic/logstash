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

    def self.create(plugins_arg)
      AVAILABLES_STRATEGIES.each do |strategy|
        if installer = strategy.get_installer_for(plugins_arg.first)
          return installer
        end
      end
      return false
    end
  end
end end
