require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager/util'
require 'rubygems/spec_fetcher'

class LogStash::PluginManager::List < Clamp::Command

  parameter "[PLUGIN]", "Part of plugin name to search for, leave empty for all plugins"

  option "--installed", :flag, "List only explicitly installed plugins using bin/plugin install ...", :default => false
  option "--verbose", :flag, "Also show plugin version number", :default => false
  option "--group", "NAME", "Filter plugins per group: input, output, filter or codec" do |arg|
    raise(ArgumentError, "should be one of: input, output, filter or codec") unless ['input', 'output', 'filter', 'codec'].include?(arg)
    arg
  end

  def execute
    require 'logstash/environment'
    LogStash::Environment.bundler_setup!

    Gem.configuration.verbose = false

    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load

    # start with all locally installed plugin gems regardless of the Gemfile content
    specs = LogStash::PluginManager.find_plugins_gem_specs

    # apply filters
    specs = specs.select{|spec| gemfile.find(spec.name)} if installed?
    specs = specs.select{|spec| spec.name =~ /#{plugin}/i} if plugin
    specs = specs.select{|spec| spec.metadata['logstash_group'] == group} if group

    raise(LogStash::PluginManager::Error, "No plugins found") if specs.empty?

    specs.sort_by{|spec| spec.name}.each do |spec|
      line = "#{spec.name}"
      line += " (#{spec.version})" if verbose?
      puts(line)
    end
  end
end # class Logstash::PluginManager
