require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager/util'
require 'rubygems/spec_fetcher'

class LogStash::PluginManager::List < Clamp::Command

  parameter "[PLUGIN]", "Plugin name to search for, leave empty for all plugins"

  option "--all", :flag, "Also list plugins installed as dependencies"
  option "--group", "NAME", "Filter plugins per group: input, output, filter or codec" do |arg|
    raise(ArgumentError, "should be one of: input, output, filter or codec") unless ['input', 'output', 'filter', 'codec'].include?(arg)
    arg
  end

  def execute
    Gem.configuration.verbose = false

    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load

    specs = all? ? LogStash::PluginManager.find_plugins_gem_specs : LogStash::PluginManager.all_installed_plugins_gem_specs(gemfile)
    specs = specs.select{|spec| spec.name =~ /#{plugin}/i} if plugin
    specs = specs.select{|spec| spec.metadata['logstash_group'] == group} if group

    if specs.empty?
      $stderr.puts("No plugins found")
      return 99
    end

    puts("> Installed plugins:")
    if all?
      installed, dependencies = specs.partition{|spec| !!gemfile.find(spec.name)}
      show_plugins(installed)
      puts("> Plugins dependencies:")
      show_plugins(dependencies)
    else
      show_plugins(specs)
    end
  end

  private

  def show_plugins(specs)
    specs.sort_by{|spec| spec.name}.each{|spec| puts("#{spec.name} (#{spec.version})")}
  end

end # class Logstash::PluginManager
