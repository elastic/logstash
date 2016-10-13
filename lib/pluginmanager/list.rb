# encoding: utf-8
require 'rubygems/spec_fetcher'
require "pluginmanager/command"

class LogStash::PluginManager::List < LogStash::PluginManager::Command

  parameter "[PLUGIN]", "Part of plugin name to search for, leave empty for all plugins"

  option "--installed", :flag, "List only explicitly installed plugins using bin/logstash-plugin install ...", :default => false
  option "--verbose", :flag, "Also show plugin version number", :default => false
  option "--group", "NAME", "Filter plugins per group: input, output, filter or codec" do |arg|
    raise(ArgumentError, "should be one of: input, output, filter or codec") unless ['input', 'output', 'filter', 'codec', 'pack'].include?(arg)
    arg
  end

  def execute
    LogStash::Bundler.setup!({:without => [:build, :development]})

    signal_error("No plugins found") if filtered_specs.empty?

    filtered_specs.sort_by{|spec| spec.name}.each do |spec|
      line = "#{spec.name}"
      line += " (#{spec.version})" if verbose?
      puts(line)
    end
  end

  def filtered_specs
    @filtered_specs ||= begin
                          # start with all locally installed plugin gems regardless of the Gemfile content
                          specs = LogStash::PluginManager.find_plugins_gem_specs

                          # apply filters
                          specs = specs.select{|spec| gemfile.find(spec.name)} if installed?
                          specs = specs.select{|spec| spec.name =~ /#{plugin}/i} if plugin
                          specs = specs.select{|spec| spec.metadata['logstash_group'] == group} if group

                          specs
                        end
  end
end # class Logstash::PluginManager
