# encoding: utf-8
require "pluginmanager/command"
require "pluginmanager/errors"

class LogStash::PluginManager::PrepareOfflinePack < LogStash::PluginManager::Command
  parameter "[PLUGIN] ...", "plugin name(s)", :attribute_name => :plugins_arg
  option "--output", "OUTPUT", "output file", :default => ::File.join(LogStash::Environment::LOGSTASH_HOME, "logstash-offline-plugins-#{LOGSTASH_VERSION}.zip")

  def execute
    validate_arguments!

    # We need to start bundler, dependencies so  the plugins are available for the prepare
    LogStash::Bundler.setup!({:without => [:build, :development]})

    # manually require paquet since its an external dependency
    require "pluginmanager/offline_plugin_packager"
    require "paquet"
    require "paquet/shell_ui"

    # Override the shell output with the one from the plugin manager
    # To silence some of debugs/info statements
    Paquet.ui = Paquet::SilentUI unless debug?

    FileUtils.rm_rf(output) if ::File.exist?(output)

    LogStash::PluginManager::OfflinePluginPackager.package(plugins_arg, output)

    message = <<-EOS
Offline package created at: #{output}

You can install it with this command `bin/logstash-plugin install file://#{::File.expand_path(output)}`
    EOS

    LogStash::PluginManager::ui.info(message)
  rescue LogStash::PluginManager::UnpackablePluginError => e
    report_exception("Offline package", e)
  rescue LogStash::PluginManager::PluginNotFoundError => e
    report_exception("Cannot create the offline archive", e)
  end

  def validate_arguments!
    if plugins_arg.size == 0
      message = <<-EOS
You need to specify at least one plugin or use a wildcard expression.

Examples:
bin/logstash-plugin prepare-offline-pack logstash-input-beats
bin/logstash-plugin prepare-offline-pack logstash-filter-jdbc logstash-input-beats
bin/logstash-plugin prepare-offline-pack logstash-filter-*
bin/logstash-plugin prepare-offline-pack logstash-filter-* logstash-input-beats

You can get a list of the installed plugin by running `bin/logstash-plugin list`

The prepare offline will pack the currently installed plugins and their dependencies
for offline installation.
EOS
      signal_usage_error(message)
    end
  end
end

