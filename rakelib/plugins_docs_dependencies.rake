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

    plugins_to_install = (all_plugins - successful_dependencies.keys).delete_if { |name| name =~ /^logstash-core/ }

    measure_execution("batch install of plugins") do
      install_plugins_sequential(plugins_to_install, successful_dependencies, failures)
    end

    return [successful_dependencies, failures]
  end

  def install_plugins_sequential(plugins_to_install, successful_dependencies, failures)
    total = plugins_to_install.size + successful_dependencies.size
    puts "Default installed: #{successful_dependencies.size} Total available plugins: #{total}"

    plugins_to_install.each do |plugin|
      begin
        builder = Bundler::Dsl.new
        gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
        gemfile.update(plugin)

        builder.eval_gemfile("bundler file", gemfile.generate())
        definition = builder.to_definition(LogStash::Environment::LOCKFILE, {})
        definition.resolve_remotely!
        extract_versions(definition, successful_dependencies, :missing)
        puts "Successfully installed: #{plugin}"
      rescue => e
        puts "Failed to install: #{plugin}"

        failures[plugin] = {
          "klass" => e.class,
          "message" => e.message
        }
      end
    end

    puts "Successful: #{successful_dependencies.size}/#{total}"
    puts "Failures: #{failures.size}/#{total}"
  end

  def extract_versions(definition, dependencies, from)
    #definition.specs.select { |spec| spec.metadata && spec.metadata["logstash_plugin"] == "true" }.each do |spec|
    #
    # Bundler doesn't seem to provide us with `spec.metadata` for remotely
    # discovered plugins (via rubygems.org api), so we have to choose by
    # a name pattern instead of by checking spec.metadata["logstash_plugin"]
    definition.specs.select { |spec| spec.name =~ /^logstash-(input|filter|output|codec)-/ }.each do |spec|
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