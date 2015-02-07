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
    Gem.configuration.verbose = false

    specs = LogStash::PluginManager.find_plugins_gem_specs
    specs = specs.select{|spec| spec.name =~ /#{plugin}/i} if plugin
    specs = specs.select{|spec| spec.metadata['logstash_group'] == group} if group

    $stderr.puts("No plugins found") if specs.empty?

    specs.each {|spec| puts("#{spec.name} (#{spec.version})") }
  end

end # class Logstash::PluginManager
