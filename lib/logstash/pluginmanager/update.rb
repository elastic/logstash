require 'clamp'
require 'logstash/namespace'
require 'logstash/pluginmanager/util'
require 'jar-dependencies'
require 'jar_install_post_install_hook'
require 'file-dependencies/gem'

require "logstash/gemfile"
require "logstash/bundler"

class LogStash::PluginManager::Update < Clamp::Command
  parameter "[PLUGIN] ...", "Plugin name(s) to upgrade to latest version"

  def execute
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    previous_gem_specs_map = find_latest_gem_specs

    # create list of plugins to update
    plugins = unless plugin_list.empty?
      not_installed = plugin_list.select{|plugin| !previous_gem_specs_map.has_key?(plugin.downcase)}
      raise(LogStash::PluginManager::Error, "Plugin #{not_installed.join(', ')} has not been previously installed, aborting") unless not_installed.empty?
      plugin_list
    else
      previous_gem_specs_map.values.map{|spec| spec.name}
    end

    # remove any version constrain from the Gemfile so the plugin(s) can be updated to latest version
    # calling update without requiremend will remove any previous requirements
    plugins.select{|plugin| gemfile.find(plugin)}.each{|plugin| gemfile.update(plugin)}
    gemfile.save

    puts("Updating " + plugins.join(", "))

    # any errors will be logged to $stderr by invoke_bundler!
    output, exception = LogStash::Bundler.invoke_bundler!(:update => plugins)
    output, exception = LogStash::Bundler.invoke_bundler!(:clean => true) unless exception

    if exception
      # revert to original Gemfile content
      gemfile.gemset = original_gemset
      gemfile.save

      report_exception(output, exception)
    end

    update_count = 0
    find_latest_gem_specs.values.each do |spec|
      name = spec.name.downcase
      if previous_gem_specs_map.has_key?(name)
        if spec.version != previous_gem_specs_map[name].version
          puts("Updated #{spec.name} #{previous_gem_specs_map[name].version.to_s} to #{spec.version.to_s}")
          update_count += 1
        end
      else
        puts("Installed #{spec.name} #{spec.version.to_s}")
        update_count += 1
      end
    end
    puts("No plugin updated") if update_count.zero?
  end

  private

  # retrieve only the latest spec for all locally installed plugins
  # @return [Hash] result hash {plugin_name.downcase => plugin_spec}
  def find_latest_gem_specs
    LogStash::PluginManager.find_plugins_gem_specs.inject({}) do |result, spec|
      previous = result[spec.name.downcase]
      result[spec.name.downcase] = previous ? [previous, spec].max_by{|s| s.version} : spec
      result
    end
  end

  def report_exception(output, exception)
    if ENV["DEBUG"]
      $stderr.puts(output)
      $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
    end

    raise(LogStash::PluginManager::Error, "Update aborted")
  end
end
