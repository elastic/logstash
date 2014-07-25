require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager'
require 'logstash/pluginmanager/util'
require 'rubygems/spec_fetcher'

class LogStash::PluginManager::List < Clamp::Command

  parameter "[PLUGIN]", "Plugin name to search for, leave empty for all plugins"

  option "--group", "NAME", "Show all plugins from a certain group. Can be one of 'output', 'input', 'codec', 'filter'"

  def execute

    if group
      unless ['input', 'output', 'filter', 'codec'].include?(group)
        signal_usage_error "Group name not valid"
      end
      plugin_name = nil
    else
      plugin_name = plugin
    end

    Gem.configuration.verbose = false

    # If we are listing a group make sure we check all gems
    specs = LogStash::PluginManager::Util.matching_specs(plugin_name) \
            .select{|spec| LogStash::PluginManager::Util.logstash_plugin?(spec) } \
            .select{|spec| group ? group == spec.metadata['logstash_group'] : true}
    if specs.empty?
      $stderr.puts ("No plugins found.")
      exit(99)
    end
    specs.each {|spec| puts ("#{spec.name} (#{spec.version})") }

  end

end # class Logstash::PluginManager
