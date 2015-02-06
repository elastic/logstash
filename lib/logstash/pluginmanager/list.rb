require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager/util'
require 'rubygems/spec_fetcher'

class LogStash::PluginManager::List < Clamp::Command

  parameter "[PLUGIN]", "Plugin name to search for, leave empty for all plugins"

  option "--group", "NAME", "Filter plugins per group: input, output, filter or codec" do |arg|
    raise(ArgumentError, "should be one of: input, output, filter or codec") unless ['input', 'output', 'filter', 'codec'].include?(arg)
    arg
  end

  def execute
    plugin_name = group ? nil : plugin

    Gem.configuration.verbose = false

    # If we are listing a group make sure we check all gems
    specs = LogStash::PluginManager::Util.matching_specs(plugin_name) \
            .select{|spec| LogStash::PluginManager::Util.logstash_plugin?(spec) } \
            .select{|spec| group ? group == spec.metadata['logstash_group'] : true}
    if specs.empty?
      $stderr.puts ("No plugins found.")
      return 0
    end
    specs.each {|spec| puts ("#{spec.name} (#{spec.version})") }
    return 0
  end

end # class Logstash::PluginManager
