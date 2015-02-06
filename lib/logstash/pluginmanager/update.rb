require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager/util'
require 'jar-dependencies'
require 'jar_install_post_install_hook'
require 'file-dependencies/gem'

require "logstash/gemfile"
require "bundler/cli"
require "logstash/bundler_patch"

class LogStash::PluginManager::Update < Clamp::Command
  parameter "[PLUGIN]", "Plugin name to upgrade to latest version"

  def execute
    puts("Updating " + (plugin ? plugin : "all plugins"))

    # any errors will be logged to $stderr by invoke_bundler!
    output, exception = LogStash::PluginManager.invoke_bundler!(:update => (plugin || true))
    if ENV["DEBUG"]
      $stderr.puts(output)
      $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
    end
    return exception ? 99 : 0
  end

  # def execute
  #   LogStash::Environment.load_logstash_gemspec!
  #   ::Gem.configuration.verbose = false
  #   ::Gem.configuration[:http_proxy] = proxy

  #   if plugin.nil?
  #     puts ("Updating all plugins")
  #   else
  #     puts ("Updating #{plugin} plugin")
  #   end

  #   specs = LogStash::PluginManager::Util.matching_specs(plugin).select{|spec| LogStash::PluginManager::Util.logstash_plugin?(spec) }
  #   if specs.empty?
  #     $stderr.puts ("No plugins found to update or trying to update a non logstash plugin.")
  #     return 99
  #   end
  #   specs.each { |spec| update_gem(spec, version) }
  #   return 0
  # end


  # def update_gem(spec, version)

  #   unless gem_path = LogStash::PluginManager::Util.download_gem(spec.name, version)
  #     $stderr.puts ("Plugin '#{spec.name}' does not exist remotely. Skipping.")
  #     return 0
  #   end

  #   unless gem_meta = LogStash::PluginManager::Util.logstash_plugin?(gem_path)
  #     $stderr.puts ("Invalid logstash plugin gem. skipping.")
  #     return 99
  #   end

  #   unless Gem::Version.new(gem_meta.version) > Gem::Version.new(spec.version)
  #     puts ("No newer version available for #{spec.name}. skipping.")
  #     return 0
  #   end

  #   puts ("Updating #{spec.name} from version #{spec.version} to #{gem_meta.version}")

  #   if LogStash::PluginManager::Util.installed?(spec.name)
  #     ::Gem.done_installing_hooks.clear
  #     ::Gem::Uninstaller.new(gem_meta.name, {:force => true}).uninstall
  #   end

  #   ::Gem.configuration.verbose = false
  #   FileDependencies::Gem.hook
  #   options = {}
  #   options[:document] = []
  #   inst = Gem::DependencyInstaller.new(options)
  #   inst.install spec.name, gem_meta.version
  #   specs, _ = inst.installed_gems
  #   puts ("Update successful")
  #   return 0
  # end

end # class Logstash::PluginManager
