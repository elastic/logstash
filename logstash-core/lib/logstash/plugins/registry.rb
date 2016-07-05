# encoding: utf-8
require 'singleton'
require "rubygems/package"

module LogStash
  class Registry

    ##
    # Placeholder class for registered plugins
    ##
    class Plugin
      attr_reader :type, :name

      def initialize(type, name)
        @type  = type
        @name  = name
      end

      def path
        "logstash/#{type}s/#{name}"
      end

      def cannonic_gem_name
        "logstash-#{type}-#{name}"
      end

      def installed?
        find_plugin_spec(cannonic_gem_name).any?
      end

      private

      def find_plugin_spec(name)
        specs = ::Gem::Specification.find_all_by_name(name)
        specs.select{|spec| logstash_plugin_spec?(spec)}
      end

      def logstash_plugin_spec?(spec)
        spec.metadata && spec.metadata["logstash_plugin"] == "true"
      end

    end

    include Singleton

    def initialize
      @registry = {}
      @logger = Cabin::Channel.get(LogStash)
    end

    def lookup(type, plugin_name, &block)

      plugin = Plugin.new(type, plugin_name)

      if plugin.installed?
        return @registry[plugin.path] if registered?(plugin.path)
        require plugin.path
        klass = @registry[plugin.path]
        if block_given? # if provided pass a block to do validation
          raise LoadError unless block.call(klass, plugin_name)
        end
        return klass
      else
        # The plugin was defined directly in the code, so there is no need to use the
        # require way of loading classes
        return @registry[plugin.path] if registered?(plugin.path)
        raise LoadError
      end
    rescue => e
      @logger.debug("Problems loading a plugin with", "type" => type, "name" => plugin, "path" => plugin.path, "error" => e) if @logger.is_debug_enabled
      raise LoadError, "Problems loading the requested plugin named #{plugin_name} of type #{type}."
    end

    def register(path, klass)
      @registry[path] = klass
    end

    def registered?(path)
      @registry.has_key?(path)
    end

  end
end
