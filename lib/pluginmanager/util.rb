# encoding: utf-8
require "rubygems/package"

module LogStash::PluginManager

  class ValidationError < StandardError; end

  # check for valid logstash plugin gem name & version or .gem file, logs errors to $stdout
  # uses Rubygems API and will remotely validated agains the current Gem.sources
  # @param plugin [String] plugin name or .gem file path
  # @param version [String] gem version requirement string
  # @param [Hash] options the options used to setup external components
  # @option options [Array<String>] :rubygems_source Gem sources to lookup for the verification
  # @return [Boolean] true if valid logstash plugin gem name & version or a .gem file
  def self.logstash_plugin?(plugin, version = nil, options={})

    if plugin_file?(plugin)
      begin
        return logstash_plugin_gem_spec?(plugin_file_spec(plugin))
      rescue => e
        $stderr.puts("Error reading plugin file #{plugin}, caused by #{e.class}")
        $stderr.puts(e.message) if ENV["DEBUG"]
        return false
      end
    else
      dep = Gem::Dependency.new(plugin, version || Gem::Requirement.default)
      Gem.sources = Gem::SourceList.from(options[:rubygems_source]) if options[:rubygems_source]
      specs, errors = Gem::SpecFetcher.fetcher.spec_for_dependency(dep)

      # dump errors
      errors.each { |error| $stderr.puts(error.wordy) }

      # depending on version requirements, multiple specs can be returned in which case
      # we will grab the one with the highest version number
      if latest = specs.map(&:first).max_by(&:version)
        unless valid = logstash_plugin_gem_spec?(latest)
          $stderr.puts("#{plugin} is not a Logstash plugin")
        end
        return valid
      else
        $stderr.puts("Plugin #{plugin}" + (version ? " version #{version}" : "") + " does not exist") if errors.empty?
        return false
      end
    end
  end

  # Fetch latest version information as in rubygems
  # @param [String] The plugin name
  # @param [Hash] Set of available options when fetching the information
  # @option options [Boolean] :pre Include pre release versions in the search (default: false)
  # @return [Hash] The plugin version information as returned by rubygems
  def self.fetch_latest_version_info(plugin, options={})
    require "gems"
    exclude_prereleases =  options.fetch(:pre, false)
    versions = Gems.versions(plugin)
    raise ValidationError.new("Something went wrong with the validation. You can skip the validation with the --no-verify option") if !versions.is_a?(Array) || versions.empty?
    versions = versions.select { |version| !version["prerelease"] } if !exclude_prereleases
    versions.first
  end

  # Let's you decide to update to the last version of a plugin if this is a major version
  # @param [String] A plugin name
  # @return [Boolean] True in case the update is moving forward, false otherwise
  def self.update_to_major_version?(plugin_name)
    plugin_version  = fetch_latest_version_info(plugin_name)
    latest_version  = plugin_version['number'].split(".")
    current_version = Gem::Specification.find_by_name(plugin_name).version.version.split(".")
    if (latest_version[0].to_i > current_version[0].to_i)
      ## warn if users want to continue
      puts("You are updating #{plugin_name} to a new version #{latest_version.join('.')}, which may not be compatible with #{current_version.join('.')}. are you sure you want to proceed (Y/N)?")
      return ( "y" == STDIN.gets.strip.downcase ? true : false)
    end
    true
  end

  # @param spec [Gem::Specification] plugin gem specification
  # @return [Boolean] true if this spec is for an installable logstash plugin
  def self.logstash_plugin_gem_spec?(spec)
    spec.metadata && spec.metadata["logstash_plugin"] == "true"
  end

  # @param path [String] path to .gem file
  # @return [Gem::Specification] .get file gem specification
  # @raise [Exception] Gem::Package::FormatError will be raised on invalid .gem file format, might be other exceptions too
  def self.plugin_file_spec(path)
    Gem::Package.new(path).spec
  end

  # @param plugin [String] the plugin name or the local path to a .gem file
  # @return [Boolean] true if the plugin is a local .gem file
  def self.plugin_file?(plugin)
    (plugin =~ /\.gem$/ && File.file?(plugin))
  end

  # retrieve gem specs for all or specified name valid logstash plugins locally installed
  # @param name [String] specific plugin name to find or nil for all plungins
  # @return [Array<Gem::Specification>] all local logstash plugin gem specs
  def self.find_plugins_gem_specs(name = nil)
    specs = name ? Gem::Specification.find_all_by_name(name) : Gem::Specification.find_all
    specs.select{|spec| logstash_plugin_gem_spec?(spec)}
  end

  # list of all locally installed plugins specs specified in the Gemfile.
  # note that an installed plugin dependecies like codecs will not be listed, only those
  # specifically listed in the Gemfile.
  # @param gemfile [LogStash::Gemfile] the gemfile to validate against
  # @return [Array<Gem::Specification>] list of plugin specs
  def self.all_installed_plugins_gem_specs(gemfile)
    # we start form the installed gemspecs so we can verify the metadata for valid logstash plugin
    # then filter out those not included in the Gemfile
    find_plugins_gem_specs.select{|spec| !!gemfile.find(spec.name)}
  end

  # @param plugin [String] plugin name
  # @param gemfile [LogStash::Gemfile] the gemfile to validate against
  # @return [Boolean] true if the plugin is an installed logstash plugin and spefificed in the Gemfile
  def self.installed_plugin?(plugin, gemfile)
    !!gemfile.find(plugin) && find_plugins_gem_specs(plugin).any?
  end

  # @param plugin_list [Array] array of [plugin name, version] tuples
  # @return [Array] array of [plugin name, version, ...] tuples when duplciate names have been merged and non duplicate version requirements added
  def self.merge_duplicates(plugin_list)

    # quick & dirty naive dedup for now
    # TODO: properly merge versions requirements
    plugin_list.uniq(&:first)
  end
end
