# encoding: utf-8
class PluginVersionWorking
  EXPORT_FILE = ::File.expand_path(::File.join(::File.dirname(__FILE__), "..", "plugins_version_docs.json"))

  # Simple class to make sure we get the right version for the document
  # since we will record multiple versions for one plugin
  class VersionDependencies
    attr_reader :version, :priority, :from

    def initialize(version, from)
      @version = version
      @from = from
      @priority = from == :default ? 1 : -1
    end

    def eql?(other)
      version == other.version && priority == other.priority
    end

    def <=>(other)
      if eql?(other)
        0
      else
        [priority, version] <=> [other.priority, other.version]
      end
    end

    def to_hash(hash = {})
      {
        "version" => version,
        "from" => from
      }
    end

    def to_s
      "from:#{from}, version: #{version}"
    end
  end

  def measure_execution(label)
    started_at = Time.now
    response = yield
    puts "Execution of label: #{label}, #{Time.now - started_at}s"
    response
  end

  def all_plugins
    measure_execution("Fetch all available plugins on `logstash-plugins`") do
      LogStash::RakeLib.fetch_all_plugins.delete_if { |name| name =~ /^logstash-mixin-/ }
    end
  end


  # We us a brute force strategy to get the highest version possible for all the community plugins.
  # We take each plugin and we add it to the current dependencies and we try to resolve the tree, if it work we
  # record the version installed.
  def retrieve_definitions
    builder = Bundler::Dsl.new
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load

    successful_dependencies = {}
    failures = {}

    builder.eval_gemfile("bundler file", gemfile.generate())
    definition = builder.to_definition(LogStash::Environment::LOCKFILE, {})
    extract_versions(definition, successful_dependencies, :default)

    plugins_to_install = all_plugins - successful_dependencies.keys
    plugins_to_install, partition_size = optimize_for_successful_resolution(plugins_to_install)
    measure_execution("batch install of plugins") do
      batch_install(plugins_to_install, successful_dependencies, failures, partition_size)
    end

    return [successful_dependencies, failures]
  end

  # If we found the result of a previous execution we will use the successful plugins result
  # to order the current plugins, we assume that the plugin that was successful will still be successful.
  # This help us reduce the number of resolve call and make the generation 3 times faster.
  def optimize_for_successful_resolution(plugins_to_install)
    if ::File.exist?(EXPORT_FILE)
      content = JSON.parse(::File.read(EXPORT_FILE))

      possible_success = []
      possible_failures = []
      unknown = []

      plugins_to_install.each do |name|
        if content["successful"][name].nil?
          if content["failures"][name].nil?
            unknown << name
          else
            possible_failures << name
          end
        else
          possible_success << name
        end
      end

      plugins_to_install = possible_success.concat(possible_failures).concat(unknown)
      [plugins_to_install, plugins_to_install.size / possible_success.size]
    else
      [plugins_to_install, 2]
    end
  end

  # Try to recursively do batch operation on the plugin list to reduce the number of resolution required.
  def batch_install(plugins_to_install, successful_dependencies, failures, partition_size = 2)
    plugins_to_install.each_slice(plugins_to_install.size /  partition_size) do |partition|
      install(partition, successful_dependencies, failures)
    end
  end

  def resolve_plugins(plugins_to_install)
      builder = Bundler::Dsl.new
      gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
      plugins_to_install.each { |plugin_name| gemfile.update(plugin_name) }
      builder.eval_gemfile("bundler file", gemfile.generate())
      definition = builder.to_definition(LogStash::Environment::LOCKFILE, {})
      definition.resolve_remotely!
      definition
  end

  def install(plugins_to_install, successful_dependencies, failures)
    begin
      definition = resolve_plugins(plugins_to_install)
      extract_versions(definition, successful_dependencies, :missing)
      puts "Batch install size: #{plugins_to_install.size}, Succesfully resolved: #{plugins_to_install}"
    rescue => e
      definition = nil # mark it to GC

      if plugins_to_install.size > 1
        batch_install(plugins_to_install, successful_dependencies, failures)
      else
        puts "Failed to install: #{plugins_to_install.first}"
        failures[plugins_to_install.first] = {
          "klass" => e.class,
          "message" => e.message
        }
      end
    end
  end

  def extract_versions(definition, dependencies, from)
    definition.specs.each do |spec|
      dependencies[spec.name] ||= []
      dependencies[spec.name] << VersionDependencies.new(spec.version, from)
    end
  end

  def generate
    specs, failures = retrieve_definitions
    filtered = specs.each_with_object({}) { |(k, v), h| h[k] = v.max.to_hash }
    result = JSON.pretty_generate({ "successful" => filtered, "failures" => failures})
    puts "Generating: #{EXPORT_FILE}"
    IO.write(EXPORT_FILE, result)
  end
end

task :generate_plugins_version do
  require "bundler"
  require "bundler/dsl"
  require "json"
  Bundler.setup(:default)
  require "pluginmanager/gemfile"
  require "bootstrap/environment"

  PluginVersionWorking.new.generate
end
