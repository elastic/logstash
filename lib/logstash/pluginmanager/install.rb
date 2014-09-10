require 'clamp'
require 'logstash/namespace'
require 'logstash/environment'
require 'logstash/pluginmanager'
require 'logstash/pluginmanager/util'
require 'rubygems/dependency_installer'
require 'rubygems/uninstaller'
require 'jar-dependencies'
require 'jar_install_post_install_hook'

class LogStash::PluginManager::Install < Clamp::Command

  parameter "PLUGIN", "plugin name or file"

  option "--version", "VERSION", "version of the plugin to install", :default => ">= 0"

  option "--proxy", "PROXY", "Use HTTP proxy for remote operations"

  def execute
    LogStash::Environment.load_logstash_gemspec!

    ::Gem.configuration.verbose = false
    ::Gem.configuration[:http_proxy] = proxy 

    puts ("validating #{plugin} #{version}")

    unless gem_path = (plugin =~ /\.gem$/ && File.file?(plugin)) ? plugin : LogStash::PluginManager::Util.download_gem(plugin, version)
      $stderr.puts ("Plugin does not exist '#{plugin}'. Aborting")
      exit(99)
    end

    unless gem_meta = LogStash::PluginManager::Util.logstash_plugin?(gem_path)
      $stderr.puts ("Invalid logstash plugin gem '#{plugin}'. Aborting...")
      exit(99)
    end

    puts ("valid logstash plugin. Continueing...")

    if LogStash::PluginManager::Util.installed?(gem_meta.name)

      current = Gem::Specification.find_by_name(gem_meta.name)
      if Gem::Version.new(current.version) > Gem::Version.new(gem_meta.version)
        unless LogStash::PluginManager::Util.ask_yesno("Do you wish to downgrade this plugin?")
          $stderr.puts("Aborting installation")
          exit(99)
        end
      end

      puts ("removing existing plugin before installation")
      ::Gem.done_installing_hooks.clear
      ::Gem::Uninstaller.new(gem_meta.name, {}).uninstall
    end

    ::Gem.configuration.verbose = false
    options = {}
    options[:document] = []
    inst = Gem::DependencyInstaller.new(options)
    inst.install plugin, version
    specs, _ = inst.installed_gems
    puts ("Successfully installed '#{specs.name}' with version '#{specs.version}'")

  end

end # class Logstash::PluginManager
