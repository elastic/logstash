require "clamp"
require "logstash/namespace"
require "logstash/environment"
require "logstash/pluginmanager/util"
require "logstash/pluginmanager/base"
require "jar-dependencies"
require "jar_install_post_install_hook"
require "file-dependencies/gem"
require "logstash/gemfile"
require "logstash/bundler"
require "fileutils"

class LogStash::PluginManager::Install < LogStash::PluginManager::Base
  parameter "[PLUGIN] ...", "plugin name(s) or file"
  option "--version", "VERSION", "version of the plugin to install"
  option "--[no-]verify", :flag, "verify plugin validity before installation", :default => true
  option "--development", :flag, "install all development dependencies of currently installed plugins", :default => false

  # the install logic below support installing multiple plugins with each a version specification
  # but the argument parsing does not support it for now so currently if specifying --version only
  # one plugin name can be also specified.
  def execute
    validate_cli_options!
    
    if local_gems?
      gems = extract_local_gems_plugins
    elsif development?
      gems = plugins_development_gems
    else
      gems = plugins_gems
      verify!(gems)
    end

    install_gems_list!(gems)
    remove_unused_locally_installed_gems! 
  end

  private
  def validate_cli_options!
    if development?
      signal_usage_error("Cannot specify plugin(s) with --development, it will add the development dependencies of the currently installed plugins") unless plugin_list.empty?
    else
      signal_usage_error("No plugin specified") if plugin_list.empty? && verify?
      # TODO: find right syntax to allow specifying list of plugins with optional version specification for each
      signal_usage_error("Only 1 plugin name can be specified with --version") if version && plugin_list.size > 1
    end
    signal_error("File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting") unless ::File.writable?(LogStash::Environment::GEMFILE_PATH)
  end

  # Check if the specified gems contains
  # the logstash `metadata`
  def verify!(gems)
    if verify?
      gems.each do |plugin, version|
        puts("Validating #{[plugin, version].compact.join("-")}")
        signal_error("Installation aborted, verification failed for #{plugin} #{version}") unless LogStash::PluginManager.logstash_plugin?(plugin, version)
      end 
    end
  end

  def plugins_development_gems
    # Get currently defined gems and their dev dependencies
    specs = []

    specs = LogStash::PluginManager.all_installed_plugins_gem_specs(gemfile)

    # Construct the list of dependencies to add to the current gemfile
    specs.each_with_object([]) do |spec, install_list|
      dependencies = spec.dependencies 
        .select { |dep| dep.type == :development }
        .map { |dep| [dep.name] + dep.requirement.as_list }

      install_list.concat(dependencies)
    end
  end

  def plugins_gems
    version ? [plugin_list << version] : plugin_list.map { |plugin| [plugin, nil] }
  end

  # install_list will be an array of [plugin name, version, options] tuples, version it
  # can be nil at this point we know that plugin_list is not empty and if the
  # --version is specified there is only one plugin in plugin_list
  #
  def install_gems_list!(install_list)
    # If something goes wrong during the installation `LogStash::Gemfile` will restore a backup version.
    install_list = LogStash::PluginManager.merge_duplicates(install_list)

    # Add plugins/gems to the current gemfile
    puts("Installing" + (install_list.empty? ? "..." : " " + install_list.collect(&:first).join(", ")))
    install_list.each { |plugin, version, options| gemfile.update(plugin, version, options) }

    # Sync gemfiles changes to disk to make them available to the `bundler install`'s API
    gemfile.save

    bundler_options = {:install => true}
    bundler_options[:without] = [] if development?
    bundler_options[:rubygems_source] = gemfile.gemset.sources

    output = LogStash::Bundler.invoke_bundler!(bundler_options)

    puts("Installation successful")
  rescue => exception
    gemfile.restore!
    report_exception("Installation Aborded", exception)
  ensure
    display_bundler_output(output)
  end

  # Extract the specified local gems in a predefined local path 
  # Update the gemfile to use a relative path to this plugin and run
  # Bundler, this will mark the gem not updatable by `bin/plugin update`
  # This is the most reliable way to make it work in bundler without 
  # hacking with `how bundler works`
  #
  # Bundler 2.0, will have support for plugins source we could create a .gem source
  # to support it.
  def extract_local_gems_plugins
    plugin_list.collect do |plugin| 
      package, path = LogStash::Bundler.unpack(plugin, LogStash::Environment::LOCAL_GEM_PATH)
      [package.spec.name, package.spec.version, { :path => relative_path(path) }]
    end
  end

  # We cannot install both .gem and normal plugin in one call of `plugin install`
  def local_gems?
    return false if plugin_list.empty?

    local_gem = plugin_list.collect { |plugin| ::File.extname(plugin) == ".gem" }.uniq

    if local_gem.size == 1
      return local_gem.first
    else
      signal_usage_error("Mixed source of plugins, you can't mix local `.gem` and remote gems")
    end
  end
end # class Logstash::PluginManager
