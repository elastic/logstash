require "jar-dependencies"
require "jar_install_post_install_hook"
require "file-dependencies/gem"

class LogStash::PluginManager::Update < LogStash::PluginManager::Command
  parameter "[PLUGIN] ...", "Plugin name(s) to upgrade to latest version", :attribute_name => :plugins_arg

  def execute
    local_gems = gemfile.locally_installed_gems

    if update_all? && !local_gems.empty?
      error_plugin_that_use_path!(local_gems)
    else
      plugins_with_path = plugins_arg & local_gems
      error_plugin_that_use_path!(plugins_with_path) if plugins_with_path.size > 0
    end

    update_gems!
  end

  private
  def error_plugin_that_use_path!(plugins)
    signal_error("Update is not supported for manually defined plugins or local .gem plugin installations: #{plugins.collect(&:name).join(",")}")
  end

  def update_all?
    plugins_arg.size == 0
  end

  def update_gems!
    # If any error is raise inside the block the Gemfile will restore a backup of the Gemfile
    previous_gem_specs_map = find_latest_gem_specs

    # remove any version constrain from the Gemfile so the plugin(s) can be updated to latest version
    # calling update without requiremend will remove any previous requirements
    plugins = plugins_to_update(previous_gem_specs_map)
    plugins
      .select { |plugin| gemfile.find(plugin) }
      .each { |plugin| gemfile.update(plugin) }

    # force a disk sync before running bundler
    gemfile.save

    puts("Updating " + plugins.join(", "))

    # any errors will be logged to $stderr by invoke!
    # Bundler cannot update and clean gems in one operation so we have to call the CLI twice.
    output = LogStash::Bundler.invoke!(:update => plugins)
    output = LogStash::Bundler.invoke!(:clean => true)

    display_updated_plugins(previous_gem_specs_map)
  rescue => exception
    gemfile.restore!
    report_exception("Updated Aborted", exception)
  ensure
    display_bundler_output(output)
  end

  # create list of plugins to update
  def plugins_to_update(previous_gem_specs_map)
    if update_all?
      previous_gem_specs_map.values.map{|spec| spec.name}
    else
      not_installed = plugins_arg.select{|plugin| !previous_gem_specs_map.has_key?(plugin.downcase)}
      signal_error("Plugin #{not_installed.join(', ')} is not installed so it cannot be updated, aborting") unless not_installed.empty?
      plugins_arg
    end
  end

  # We compare the before the update and after the update
  def display_updated_plugins(previous_gem_specs_map)
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

  # retrieve only the latest spec for all locally installed plugins
  # @return [Hash] result hash {plugin_name.downcase => plugin_spec}
  def find_latest_gem_specs
    LogStash::PluginManager.find_plugins_gem_specs.inject({}) do |result, spec|
      previous = result[spec.name.downcase]
      result[spec.name.downcase] = previous ? [previous, spec].max_by{|s| s.version} : spec
      result
    end
  end
end
