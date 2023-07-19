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

require "rubygems/package"
require "logstash/plugin"
require "logstash/modules/scaffold"
require "logstash/codecs/base"
require "logstash/filters/base"
require "logstash/outputs/base"

module LogStash module Plugins
  class Registry
    include LogStash::Util::Loggable

    class UnknownPlugin < NameError; end

    # Add a bit more sanity with when interacting with the rubygems'
    # specifications database, most of out code interact directly with really low level
    # components of bundler/rubygems we need to encapsulate that and this is a start.
    class GemRegistry
      LOGSTASH_METADATA_KEY = "logstash_plugin"

      class << self
        def installed_gems
          ::Gem::Specification
        end

        def logstash_plugins
          installed_gems
            .select { |spec| spec.metadata && spec.metadata[LOGSTASH_METADATA_KEY] }
            .collect { |spec| PluginRawContext.new(spec) }
        end
      end
    end

    class PluginRawContext
      HOOK_FILE = "logstash_registry.rb"
      NAME_DELIMITER = "-"

      attr_reader :spec

      def initialize(spec)
        @spec = spec
        @destructured_name = spec.name.split(NAME_DELIMITER)
      end

      def name
        @destructured_name[2..-1].join(NAME_DELIMITER)
      end

      def type
        @destructured_name[1]
      end

      # In the context of the plugin, the hook file available  need to exist in any top level
      # required paths.
      #
      # Example for the logstash-output-elasticsearch we have this line in the gemspec.
      #
      # s.require_paths = ["lib"], so the we will expect to have a `logstash_registry.rb` file in the `lib`
      # directory.
      def hooks_file
        @hook_file ||= spec.full_require_paths.collect do |path|
          f = ::File.join(path, HOOK_FILE)
          ::File.exist?(f) ? f : nil
        end.compact.first
      end

      def has_hooks?
        !hooks_file.nil?
      end

      def execute_hooks!
        require hooks_file
      end
    end

    class PluginSpecification
      attr_reader :type, :name, :klass

      def initialize(type, name, klass)
        @type  = type.to_sym
        @name  = name
        @klass = klass
      end
    end

    class UniversalPluginSpecification < PluginSpecification
      def initialize(type, name, klass)
        super(type, name, klass)
        @instance = klass.new
      end

      def register(hooks, settings)
        @instance.register_hooks(hooks)
        @instance.additionals_settings(settings)
      end
    end

    attr_reader :hooks

    def initialize(alias_registry = nil)
      @mutex = Mutex.new
      # We need a threadsafe class here because we may perform
      # get/set operations concurrently despite the fact we don't use
      # the special atomic methods. That may not be apparent from this file,
      # but it is the case that we can call lookups from multiple threads,
      # when multiple pipelines are in play, and that a lookup may modify the registry.
      @registry = java.util.concurrent.ConcurrentHashMap.new
      @java_plugins = java.util.concurrent.ConcurrentHashMap.new
      @hooks = HooksRegistry.new
      @alias_registry = alias_registry || Java::org.logstash.plugins.AliasRegistry.instance
    end

    def setup!
      load_xpack unless LogStash::OSS
      load_available_plugins
      execute_universal_plugins
    end

    def execute_universal_plugins
      @registry.values
        .select { |specification| specification.is_a?(UniversalPluginSpecification) }
        .each { |specification| specification.register(hooks, LogStash::SETTINGS) }
    end

    def plugins_with_type(type)
      @registry.values.select { |specification| specification.type.to_sym == type.to_sym }.collect(&:klass)
    end

    def load_xpack
      logger.info("Loading x-pack")
      require("x-pack/logstash_registry")
    end

    def load_available_plugins
      require "logstash/plugins/builtin"

      GemRegistry.logstash_plugins.each do |plugin_context|
        if plugin_context.spec.metadata.key?('java_plugin')
          # Find *.jar file from the require path
          jar_files = plugin_context.spec.matches_for_glob("**/*.jar")
          expected_jar_name = plugin_context.spec.name + "-" + plugin_context.spec.version.to_s + ".jar"
          if jar_files.length != 1 || !jar_files.first.end_with?(expected_jar_name)
            raise LoadError, "Java plugin '#{plugin_context.spec.name}' does not contain a single jar file with the plugin's name and version"
          end
          @java_plugins[plugin_context.spec.name] = jar_files.first
        end

        # When a plugin has a HOOK_FILE defined, its the responsibility of the plugin
        # to register itself to the registry of available plugins.
        #
        # Legacy plugin will lazy register themselves
        if plugin_context.has_hooks?
          begin
            logger.debug("Executing hooks", :name => plugin_context.name, :type => plugin_context.type, :hooks_file => plugin_context.hooks_file)
            plugin_context.execute_hooks!
          rescue => e
            logger.error("error occured when loading plugins hooks file", :name => plugin_context.name, :type => plugin_context.type, :exception => e.message, :stacktrace => e.backtrace)
          end
        end
      end
    end

    def lookup(type, plugin_name, &block)
      @mutex.synchronize do
        plugin_spec = get(type, plugin_name)
        # Assume that we have a legacy plugin
        if plugin_spec.nil?
          plugin_spec = legacy_lookup(type, plugin_name)
        end

        raise LoadError, "No plugin found with name '#{plugin_name}'" unless plugin_spec

        if block_given? # if provided pass a block to do validation
          raise LoadError, "Block validation fails for plugin named #{plugin_name} of type #{type}," unless block.call(plugin_spec.klass, plugin_name)
        end

        plugin_spec.klass
      end
    end

    # The legacy_lookup method uses the 1.5->5.0 file structure to find and match
    # a plugin and will do a lookup on the namespace of the required class to find a matching
    # plugin with the appropriate type.
    def legacy_lookup(type, plugin_name)
      klass = load_plugin_class(type, plugin_name)

      if !klass && @alias_registry.alias?(type.to_java, plugin_name)
        resolved_plugin_name = @alias_registry.original_from_alias(type.to_java, plugin_name)
        logger.debug("Loading #{type} plugin #{resolved_plugin_name} via its alias #{plugin_name}...")
        klass = load_plugin_class(type, resolved_plugin_name)
        lazy_add(type, resolved_plugin_name, klass) if klass
      end

      unless klass
        logger.error("Unable to load plugin.", :type => type, :name => plugin_name)
        raise LoadError, "Unable to load the requested plugin named #{plugin_name} of type #{type}. The plugin is not installed."
      end

      lazy_add(type, plugin_name, klass)
    end

    # load a plugin's class, or return nil if the plugin cannot be loaded.
    # attempts to load the class purely through namespace lookup,
    # and falls back to requiring the path of the expected plugin.
    # @param type [String]: plugin type, such as "input", "output", "filter", "codec"
    # @param plugin_name [String]: plugin name, such as "grok", "elasticsearch"
    # @return [Class,nil] the plugin class, or nil
    private
    def load_plugin_class(type, plugin_name)
      klass = namespace_lookup(type, plugin_name)

      unless klass
        require("logstash/#{type}s/#{plugin_name}")
        klass = namespace_lookup(type, plugin_name)
      end
      klass
    rescue LoadError => e
      logger.debug("Tried to load a plugin's code, but failed.", :exception => e, :path => e.path, :type => type, :name => plugin_name)
      nil
    end

    public
    def lookup_pipeline_plugin(type, name)
      LogStash::PLUGIN_REGISTRY.lookup(type, name) do |plugin_klass, plugin_name|
        is_a_plugin_or_alias?(plugin_klass, type.to_java, plugin_name)
      end
    rescue LoadError, NameError => e
      logger.debug("Problems loading the plugin with", :type => type, :name => name)
      raise(LogStash::PluginLoadingError, I18n.t("logstash.pipeline.plugin-loading-error", :type => type, :name => name, :error => e.to_s))
    end

    def lazy_add(type, name, klass)
      logger.debug("On demand adding plugin to the registry", :name => name, :type => type, :class => klass)
      add_plugin(type, name, klass)
    end

    def add(type, name, klass)
      logger.debug("Adding plugin to the registry", :name => name, :type => type, :class => klass)
      add_plugin(type, name, klass)
    end

    def remove(type, plugin_name)
      @registry.delete(key_for(type, plugin_name))
    end

    def get(type, plugin_name)
      @registry[key_for(type, plugin_name)]
    end

    def exists?(type, name)
      @registry.include?(key_for(type, name))
    end

    def size
      @registry.size
    end

    private
    # lookup a plugin by type and name in the existing LogStash module namespace
    # ex.: namespace_lookup("filter", "grok") looks for LogStash::Filters::Grok
    # @param type [String] plugin type, "input", "output", "filter"
    # @param name [String] plugin name, ex.: "grok"
    # @return [Class,nil] the plugin class or nil
    def namespace_lookup(type, name)
      type_const = "#{type.capitalize}s"
      namespace = LogStash.const_get(type_const)
      # the namespace can contain constants which are not for plugins classes (do not respond to :config_name)
      # namespace.constants is the shallow collection of all constants symbols in namespace
      # note that below namespace.const_get(c) should never result in a NameError since c is from the constants collection
      klass_sym = namespace.constants.find { |c| is_a_plugin?(namespace.const_get(c), name) }
      klass_sym && namespace.const_get(klass_sym)
    end

    # check if klass is a valid plugin for name
    # @param klass [Class] plugin class
    # @param name [String] plugin name
    # @return [Boolean] true if klass is a valid plugin for name
    def is_a_plugin?(klass, name)
      (klass.class == Java::JavaLang::Class && klass.simple_name.downcase == name.gsub('_', '')) ||
      (klass.ancestors.include?(LogStash::Plugin) && klass.respond_to?(:config_name) &&
        klass.config_name == name)
    end

    # check if klass is a valid plugin for name,
    # including alias resolution
    def is_a_plugin_or_alias?(klass, type, plugin_name)
      return true if is_a_plugin?(klass, plugin_name)

      resolved_plugin_name = @alias_registry.resolve_alias(type, plugin_name)
      return true if is_a_plugin?(klass, resolved_plugin_name)

      false
    end

    def add_plugin(type, name, klass)
      if klass.respond_to?("javaClass", true)
        if LogStash::SETTINGS.get_value('pipeline.plugin_classloaders')
          full_name = 'logstash-' + key_for(type, name)
          if @java_plugins.key?(full_name)
            plugin_paths = @java_plugins[full_name]
          else
            raise LoadError,  "Could not find metadata for Java plugin: #{full_name}"
          end
          java_import org.logstash.plugins.PluginClassLoader
          java_import org.logstash.Logstash

          classloader = PluginClassLoader.create(plugin_paths, Logstash.java_class.class_loader)
          klazz = classloader.load_class(klass.javaClass.name)
          @registry[key_for(type, name)] = PluginSpecification.new(type, name, klazz.ruby_class.java_class)
        else
          @registry[key_for(type, name)] = PluginSpecification.new(type, name, klass.javaClass)
        end
      elsif !exists?(type, name)
        specification_klass = type == :universal ? UniversalPluginSpecification : PluginSpecification
        @registry[key_for(type, name)] = specification_klass.new(type, name, klass)
      else
        logger.debug("Ignoring, plugin already added to the registry", :name => name, :type => type, :klass => klass)
      end
    end

    def key_for(type, plugin_name)
      "#{type}-#{plugin_name}"
    end
  end end

  PLUGIN_REGISTRY = Plugins::Registry.new
end
