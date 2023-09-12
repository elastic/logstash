# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'json'

class PluginVersionWorking
  EXPORT_FILE = ::File.expand_path(::File.join(::File.dirname(__FILE__), "..", "plugins_version_docs.json"))
  PLUGIN_METADATA = JSON.parse(IO.read(::File.expand_path(::File.join(::File.dirname(__FILE__), "plugins-metadata.json"))))

  PLUGIN_PACKAGE_TYPES = %w(
    input
    output
    codec
    filter
    integration
  ).freeze

  PLUGIN_PACKAGE_NAME_PATTERN = %r{^logstash-#{Regexp::union(PLUGIN_PACKAGE_TYPES)}-}

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
        try_plugin(plugin, successful_dependencies)
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

  def try_plugin(plugin, successful_dependencies)
    builder = Bundler::Dsl.new
    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    gemfile.update(plugin)

    builder.eval_gemfile("bundler file", gemfile.generate())
    definition = builder.to_definition(LogStash::Environment::LOCKFILE, {})
    definition.resolve_remotely!
    from = PLUGIN_METADATA.fetch(plugin, {}).fetch("default-plugins", false) ? :default : :missing
    extract_versions(definition, successful_dependencies, from)
  end

  def extract_versions(definition, dependencies, from)
    #definition.specs.select { |spec| spec.metadata && spec.metadata["logstash_plugin"] == "true" }.each do |spec|
    #
    # Bundler doesn't seem to provide us with `spec.metadata` for remotely
    # discovered plugins (via rubygems.org api), so we have to choose by
    # a name pattern instead of by checking spec.metadata["logstash_plugin"]
    definition.resolve.select { |spec| spec.name =~ PLUGIN_PACKAGE_NAME_PATTERN }.each do |spec|
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
  require "pluginmanager/gemfile"
  require "bootstrap/environment"

  # This patch comes after an investigation of `generate_plugins_version`
  # causing OOM during `./gradlew generatePluginsVersion`.
  # Why does this patch fix the issue? Hang on, this is going to be wild ride:
  # In this rake task we compute a manifest that tells us, for each logstash plugin,
  # what is the latest version that can be installed.
  # We do this by (again for each plugin):
  # * adding the plugin to the current Gemfile
  # * instantiate a `Bundler::Dsl` instance with said Gemfile
  # * retrieve a Bundler::Definition by passing in the Gemfile.lock
  # * call `definition.resolve_remotely!
  #
  # Now, these repeated calls to `resolve_remotely!` on new instances of Definitions
  # cause the out of memory. Resolving remote dependencies uses Bundler::Worker instances
  # who trap the SIGINT signal in their `initializer` [1]. This shared helper method creates a closure that is
  # passed to `Signal.trap`, and capture the return [2], which is the previous proc (signal handler).
  # Since the variable that stores the return from `Signal.trap` is present in the binding, multiple calls
  # to this helper cause each new closures to reference the previous one. The size of each binding
  # accumulates and OOM occurs after 70-100 iterations.
  # This is easy to replicate by looping over `Bundler::SharedHelpers.trap("INT") { 1 }`.
  #
  # This workaround removes the capture of the previous binding. Not calling all the previous handlers
  # may cause some threads to not be cleaned up, but this rake task has a short life so everything
  # ends up being cleaned up on exit anyway.
  # We're confining this patch to this task only as this is the only place where we need to resolve
  # dependencies many many times.
  #
  # You're still here? You're awesome :) Thanks for reading!
  #
  # [1] https://github.com/bundler/bundler/blob/d9d75807196b91f454de48d5afd0c43b395243a3/lib/bundler/worker.rb#L29
  # [2] https://github.com/bundler/bundler/blob/d9d75807196b91f454de48d5afd0c43b395243a3/lib/bundler/shared_helpers.rb#L173
  module ::Bundler
    module SharedHelpers
      def trap(signal, override = false, &block)
        Signal.trap(signal) do
          block.call
        end
      end
    end

    Fetcher::CompactIndex.class_eval do
      alias_method :__bundle_worker, :bundle_worker
      # The compact index is built using multiple threads and this is hard-coded atm to 25 threads:
      #   `Bundler::Worker.new(Bundler.current_ruby.rbx? ? 1 : 25, worker_name, func)`
      # each thread might built up a Bundler::Source::Rubygems object which retains more than 100MB.
      # By limiting the worker thread count we make sure not to produce too many of these objects.
      def bundle_worker(func = nil)
        __bundle_worker(func).tap do |worker|
          size = worker.instance_variable_get(:@size)
          fail("@size = #{size.inspect} is no longer an integer") unless size.is_a?(Integer)
          worker.instance_variable_set(:@size, 2)
        end
      end
    end
  end

  PluginVersionWorking.new.generate
end
