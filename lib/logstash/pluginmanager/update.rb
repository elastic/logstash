require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager'
require 'logstash/pluginmanager/util'
require 'rubygems/dependency_installer'
require 'rubygems/uninstaller'
require 'jar-dependencies'
require 'jar_install_post_install_hook'

class LogStash::PluginManager::Update < Clamp::Command

  parameter "[PLUGIN]", "Plugin name"

  option "--version", "VERSION", "version of the plugin to install", :default => ">= 0"

  option "--proxy", "PROXY", "Use HTTP proxy for remote operations"

  def execute

    LogStash::Environment.load_logstash_gemspec!
    ::Gem.configuration.verbose = false
    ::Gem.configuration[:http_proxy] = proxy

    if plugin.nil?
      puts ("Updating all plugins")
    else
      puts ("Updating #{plugin} plugin")
    end

    specs = LogStash::PluginManager::Util.matching_specs(plugin).select{|spec| LogStash::PluginManager::Util.logstash_plugin?(spec) }
    if specs.empty?
      $stderr.puts ("No plugins found to update or trying to update a non logstash plugin.")
      exit(99)
    end
    specs.each { |spec| update_gem(spec, version) }

  end


  def update_gem(spec, version)

    unless gem_path = LogStash::PluginManager::Util.download_gem(spec.name, version)
      $stderr.puts ("Plugin '#{spec.name}' does not exist remotely. Skipping.")
      return nil
    end

    unless gem_meta = LogStash::PluginManager::Util.logstash_plugin?(gem_path)
      $stderr.puts ("Invalid logstash plugin gem. skipping.")
      return nil
    end

    unless Gem::Version.new(gem_meta.version) > Gem::Version.new(spec.version)
      puts ("No newer version available for #{spec.name}. skipping.")
      return nil
    end

    puts ("Updating #{spec.name} from version #{spec.version} to #{gem_meta.version}")

    if LogStash::PluginManager::Util.installed?(spec.name)
      ::Gem.done_installing_hooks.clear
      ::Gem::Uninstaller.new(gem_meta.name, {}).uninstall
    end

    ::Gem.configuration.verbose = false
    options = {}
    options[:document] = []
    inst = Gem::DependencyInstaller.new(options)
    inst.install spec.name, gem_meta.version
    specs, _ = inst.installed_gems
    puts ("Update successful")

  end

end # class Logstash::PluginManager
