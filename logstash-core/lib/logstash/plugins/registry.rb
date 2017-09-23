# encoding: utf-8
require "rubygems/package"
require "logstash/util/loggable"
require "logstash/plugin"
require "logstash/plugins/hooks_registry"
require "logstash/modules/scaffold"

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

    def initialize
      @registry = {}
      @hooks = HooksRegistry.new
    end

    def setup!
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

    def load_available_plugins
      GemRegistry.logstash_plugins.each do |plugin_context|
        # When a plugin has a HOOK_FILE defined, its the responsibility of the plugin
        # to register itself to the registry of available plugins.
        #
        # Legacy plugin will lazy register themselves
        if plugin_context.has_hooks?
          begin
            logger.debug("Executing hooks", :name => plugin_context.name, :type => plugin_context.type, :hooks_file => plugin_context.hooks_file)
            plugin_context.execute_hooks!
          rescue => e
            logger.error("error occured when loading plugins hooks file", :name => plugin_context.name, :type => plugin_context.type, :exception => e.message, :stacktrace => e.backtrace )
          end
        end
      end
    end

    def lookup(type, plugin_name, &block)
      plugin = get(type, plugin_name)
      # Assume that we have a legacy plugin
      if plugin.nil?
        plugin = legacy_lookup(type, plugin_name)
      end

      if block_given? # if provided pass a block to do validation
        raise LoadError, "Block validation fails for plugin named #{plugin_name} of type #{type}," unless block.call(plugin.klass, plugin_name)
      end

      return plugin.klass
    end

    # The legacy_lookup method uses the 1.5->5.0 file structure to find and match
    # a plugin and will do a lookup on the namespace of the required class to find a matching
    # plugin with the appropriate type.
    def legacy_lookup(type, plugin_name)
      begin
        path = "logstash/#{type}s/#{plugin_name}"

        klass = begin
          namespace_lookup(type, plugin_name)
        rescue UnknownPlugin => e
          # Plugin not registered. Try to load it.
          begin
            require path
            namespace_lookup(type, plugin_name)
          rescue LoadError => e
            logger.error("Tried to load a plugin's code, but failed.", :exception => e, :path => path, :type => type, :name => plugin_name)
            raise
          end
        end

        plugin = lazy_add(type, plugin_name, klass)
      rescue => e
        logger.error("Problems loading a plugin with",
                    :type => type,
                    :name => plugin_name,
                    :path => path,
                    :error_message => e.message,
                    :error_class => e.class,
                    :error_backtrace => e.backtrace)

        raise LoadError, "Problems loading the requested plugin named #{plugin_name} of type #{type}. Error: #{e.class} #{e.message}"
      end

      plugin
    end

    def lookup_pipeline_plugin(type, name)
      LogStash::PLUGIN_REGISTRY.lookup(type, name) do |plugin_klass, plugin_name|
        is_a_plugin?(plugin_klass, plugin_name)
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
    # @return [Class] the plugin class or raises NameError
    # @raise NameError if plugin class does not exist or is invalid
    def namespace_lookup(type, name)
      type_const = "#{type.capitalize}s"
      namespace = LogStash.const_get(type_const)
      # the namespace can contain constants which are not for plugins classes (do not respond to :config_name)
      # namespace.constants is the shallow collection of all constants symbols in namespace
      # note that below namespace.const_get(c) should never result in a NameError since c is from the constants collection
      klass_sym = namespace.constants.find { |c| is_a_plugin?(namespace.const_get(c), name) }
      klass = klass_sym && namespace.const_get(klass_sym)

      raise(UnknownPlugin) unless klass
      klass
    end

    # check if klass is a valid plugin for name
    # @param klass [Class] plugin class
    # @param name [String] plugin name
    # @return [Boolean] true if klass is a valid plugin for name
    def is_a_plugin?(klass, name)
      klass.ancestors.include?(LogStash::Plugin) && klass.respond_to?(:config_name) && klass.config_name == name
    end

    def add_plugin(type, name, klass)
      if !exists?(type, name)
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
