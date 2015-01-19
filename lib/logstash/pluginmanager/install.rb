require 'clamp'
require 'logstash/namespace'
require 'logstash/environment'
require 'logstash/pluginmanager'
require 'logstash/pluginmanager/util'
require 'rubygems/dependency_installer'
require 'rubygems/uninstaller'
require 'jar-dependencies'
require 'jar_install_post_install_hook'
require 'file-dependencies/gem'

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
      return 99
    end

    unless gem_meta = LogStash::PluginManager::Util.logstash_plugin?(gem_path)
      $stderr.puts ("Invalid logstash plugin gem '#{plugin}'. Aborting...")
      return 99
    end

    puts ("Valid logstash plugin. Continuing...")

    if LogStash::PluginManager::Util.installed?(gem_meta.name)

      current = Gem::Specification.find_by_name(gem_meta.name)
      if Gem::Version.new(current.version) > Gem::Version.new(gem_meta.version)
        unless LogStash::PluginManager::Util.ask_yesno("Do you wish to downgrade this plugin?")
          $stderr.puts("Aborting installation")
          return 99
        end
      end

      puts ("removing existing plugin before installation")
      ::Gem.done_installing_hooks.clear
      ::Gem::Uninstaller.new(gem_meta.name, {:force => true}).uninstall
    end

    ::Gem.configuration.verbose = false
    FileDependencies::Gem.hook
    options = {}
    options[:document] = []
    if LogStash::Environment.test?
      # This two options are the ones used to ask the rubygems to install
      # all development dependencies as you can do from the command line
      # tool.
      #
      # :development option for installing development dependencies.
      # :dev_shallow option for checking on the top level gems if there.
      #
      # Comments from the command line tool.
      # --development     - Install additional development dependencies
      #
      # Links: https://github.com/rubygems/rubygems/blob/master/lib/rubygems/install_update_options.rb#L150
      #        http://guides.rubygems.org/command-reference/#gem-install
      options[:dev_shallow] = true
      options[:development] = true
    end
    inst = Gem::DependencyInstaller.new(options)
    inst.install plugin, version
    specs = inst.installed_gems.detect { |gemspec| gemspec.name == gem_meta.name }
    puts ("Successfully installed '#{specs.name}' with version '#{specs.version}'")
    return 0
  end

end # class Logstash::PluginManager
