# encoding: utf-8
require "logstash/agent"

module LogStash module AgentPluginRegistry
  DEFAULT_AGENT_NAME = :default
  class DuplicatePluginError < Error; end

  REGISTRY = {}

  # Reset plugin registry to just the default plugin
  def self.reset!
    REGISTRY.clear
    REGISTRY[DEFAULT_AGENT_NAME] = LogStash::Agent
  end

  reset!

  # Search gems for available plugins and load their libs
  def self.load_all
    find_plugins.each do |plugin|
      name = plugin.name.split('-')[-1]
      require "logstash/agents/#{name}"
    end
  end

  # Return a list of Gem::Specification s that start with logstash-agent-
  def self.find_plugins
    Gem::Specification.find_all{|spec| spec.name =~ /logstash-agent-/ }
  end

  # To be called by a plugin when its class is first loaded
  # Plugins should call this with the following code:
  #
  # require 'lib/logstash/agent_plugin_registry'
  #
  # class MyLogStashAgent < LogStash::Agent
  #   LogStash::AgentPluginRegistry.register(:my_logstash_agent, self)
  #
  #   # ...
  # end
  def self.register(name, plugin_class)
    name_sym = name.to_sym

    if (conflicting_class = registry[name_sym])
      raise DuplicatePluginError, "Could not register plugin '#{plugin_class}'" <<
        " as '#{name}', this name is already taken by '#{conflicting_class}'"
    end

    registry[name_sym] = plugin_class
  end

  # A hash of plugin names to plugin classes
  def self.registry
    REGISTRY
  end

  # Get a plugin by name
  def self.lookup(name)
    registry[name.to_sym]
  end

  # List of available plugins
  def self.available
    registry.keys
  end
end end
